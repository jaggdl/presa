# frozen_string_literal: true

require "json"

module Services
  # A service that proxies an external MCP server's tools into the workspace.
  #
  # There are two ways to use it:
  #
  # 1. **Generic** (kind `mcp`): the user supplies `url` and optional `headers`
  #    JSON directly.
  #
  # 2. **Preset subclass**: a subclass (e.g. `Services::Github`) preconfigures
  #    the endpoint with `mcp_url "<fixed url>"` and one or more `mcp_header`
  #    templates, then exposes only the secret config field(s) the caller must
  #    fill in. Header templates may reference config fields via `#{name}` (or
  #    `${input:name}`) and are resolved against the instance's `config` at call
  #    time. A preset resets its `config_fields` so the fixed `url`/`headers`
  #    never appear in its form.
  #
  # Unlike the HTTP-integration services (Github's old REST client, Jellyfin)
  # whose tools are static Ruby handlers, an MCP service has no code of its own:
  # it points at a remote Model Context Protocol endpoint and re-exposes the
  # tools that server advertises.
  class Mcp < Service
    kind :mcp
    icon "mcp.png"

    config_field :url, required: true
    config_field :headers, default: "{}", textarea: true

    # Preset subclass configuration (see class DSL below).
    class_attribute :mcp_preset_url, default: nil
    class_attribute :mcp_preset_headers, default: {}

    validate :headers_must_be_valid_json

    class << self
      # Starts a preset subclass: resets the inherited generic config fields
      # (url, headers) so only the fields declared after this call appear in
      # the form. Returns self so the kind's fields can be declared next.
      #
      #   class Github < Services::Mcp
      #     preset
      #     config_field :api_token, required: true, secret: true
      #   end
      def preset
        self.config_fields = {}
        self
      end

      # Declares a fixed endpoint URL for a preset subclass. When set, it is
      # used instead of the `url` config field.
      def mcp_url(value = nil)
        self.mcp_preset_url = value.to_s if value
        mcp_preset_url
      end

      # Declares a preset header, value being a string template that may
      # reference config fields, e.g. `mcp_header "Authorization",
      # "Bearer ${github_mcp_pat}"`. When any preset headers exist,
      # `extra_headers` is built from them (templates resolved against
      # `config`) and the generic JSON `headers` field is ignored.
      def mcp_header(name, template)
        self.mcp_preset_headers = mcp_preset_headers.merge(name.to_s => template.to_s)
      end
    end

    # The header/value entries a preset introduces; empty for generic MCP.
    def mcp_preset_headers
      self.class.mcp_preset_headers
    end

    # The fixed URL declared by a preset subclass, if any.
    def mcp_preset_url
      self.class.mcp_preset_url
    end

    # The endpoint URL used for the outbound connection: the preset URL when a
    # preset declared one, else the `url` config field.
    def base_url
      mcp_preset_url.presence || config[:url]
    end

    # The extra HTTP header templates for a preset, empty otherwise.
    def header_templates
      mcp_preset_headers
    end

    # The MCP server's extra HTTP headers. Preset subclasses evaluate their
    # declared header templates against `config`; generic MCPs parse the
    # `headers` JSON config field.
    def extra_headers
      return build_preset_headers if header_templates.any?

      parse_json_headers(config[:headers])
    end

    def client
      @client ||= ::Mcp::Client.new(url: base_url, headers: extra_headers)
    end

    # Remote tool definitions ([{name, description, inputSchema}, ...]).
    # Small cache keyed on url to avoid a discovery round-trip per request.
    # Discovery is best-effort for listing: on failure it returns an empty list
    # and records `remote_tools_error` so pages can surface the reason without
    # an individual service breaking the whole list.
    def remote_tools
      @remote_tools ||= Rails.cache.fetch([ "mcp_remote_tools", base_url ], expires_in: 30.seconds) do
        client.list_tools.with_indifferent_access[:tools] || []
      end
    rescue StandardError => e
      @remote_tools_error = e
      @remote_tools = []
    end

    # The error (if any) from the last remote tool discovery attempt.
    attr_reader :remote_tools_error

    private

    # Resolve a preset header template against this service's config. Supports
    # `${input:name}`, `${name}`, and Ruby-style `#{name}` placeholders.
    # Unknown variables are left as-is.
    def resolve_template(template)
      template.to_s.gsub(/\$\{(?:input:)?([a-zA-Z0-9_]+)\}|#\{([a-zA-Z0-9_]+)\}/) do
        name = Regexp.last_match(1) || Regexp.last_match(2)
        config[name].presence || Regexp.last_match(0)
      end
    end

    def build_preset_headers
      header_templates.each_with_object({}) do |(name, template), headers|
        headers[name] = resolve_template(template)
      end
    end

    def parse_json_headers(value)
      return value if value.nil? || value.is_a?(Hash)

      JSON.parse(value)
    rescue JSON::ParserError
      {}
    end

    # Validation runs only for generic MCPs; presets do not use the `headers` JSON.
    def headers_must_be_valid_json
      return true if header_templates.any? || config[:headers].is_a?(Hash)

      JSON.parse(config[:headers].presence || "{}")
    rescue JSON::ParserError
      errors.add(:config, "headers must be valid JSON")
    end
  end
end