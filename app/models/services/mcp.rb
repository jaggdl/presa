# frozen_string_literal: true

require "json"

module Services
  # A service that proxies an external MCP server's tools into the workspace.
  #
  # Unlike the HTTP-integration services (Github, Jellyfin) whose tools are
  # static Ruby handlers, an MCP service has no code of its own: it points at a
  # remote Model Context Protocol endpoint (e.g. https://search.parallel.ai/mcp)
  # and re-exposes the tools that server advertises.
  class Mcp < Service
    kind :mcp
    icon "mcp.png"

    config_field :url, required: true
    config_field :headers, default: "{}"

    # The MCP server's extra HTTP headers, parsed from the JSON config field.
    # Used for e.g. `{"Authorization": "Bearer <key>"}`.
    def extra_headers
      value = config[:headers].presence || "{}"
      return value if value.is_a?(Hash)

      JSON.parse(value)
    rescue JSON::ParserError
      {}
    end

    def client
      @client ||= ::Mcp::Client.new(url: config[:url], headers: extra_headers)
    end

    # Remote tool definitions ([{name, description, inputSchema}, ...]).
    # Small cache keyed on url to avoid a discovery round-trip per request.
    def remote_tools
      @remote_tools ||= Rails.cache.fetch([ "mcp_remote_tools", config[:url] ], expires_in: 30.seconds) do
        client.list_tools.with_indifferent_access[:tools] || []
      end
    end
  end
end
