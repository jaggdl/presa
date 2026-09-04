# frozen_string_literal: true

require "set"
require "uri"

module Openapi
  # Turns a parsed OpenAPIParser root into the normalized, persisted shape a
  # `Services::Openapi` relies on: one entry per operation (method/path/args
  # schema/body), resolved servers, and the security schemes turned into
  # credential slots. The output is a plain Hash (string keys, JSON-safe) so it
  # can travel through the integration wizard's draft cache and finally into the
  # service's encrypted `config`.
  class Generator
    HTTP_METHODS = %i[ get put post delete options head patch trace ].freeze

    # @param root [OpenAPIParser::Schemas::OpenAPI] parsed document
    # @param source_url [String, nil] spec URL when loaded from a URL (used to
    #   resolve relative servers)
    # @param overrides [Hash] optional form overrides (e.g. a base_url)
    # @return [Hash] draft definition passed to / persisted by the wizard
    def self.generate(root, source_url: nil, overrides: {})
      new(root, source_url, (overrides || {})).generate
    end

    def initialize(root, source_url, overrides)
      @root = root
      @raw = root.raw_schema
      @source_url = source_url.to_s.presence
      @overrides = overrides.is_a?(Hash) ? overrides : {}
    end

    def generate
      {
        "title" => info["title"].to_s.presence || "Untitled API",
        "version" => info["version"].to_s.presence || "",
        "description" => info["description"].to_s.strip[0, 300].presence || "",
        "namespace_slug" => namespace_slug,
        "servers" => servers,
        "base_url" => @overrides["base_url"].presence || resolved_base_url,
        "spec_url" => @source_url,
        "security" => security_slots,
        "operations" => operations,
        "operation_count" => operations.length,
        "tag_count" => tags.length,
        "tags" => tags,
        "source" => @source_url.present? ? "url" : "raw"
      }
    end

    private

    def info
      @info ||= (@raw["info"] || {}).is_a?(Hash) ? @raw["info"] : {}
    end

    def namespace_slug
      slugify(info["title"].to_s).presence || "api"
    end

    def servers
      list = @raw["servers"].is_a?(Array) ? @raw["servers"] : []
      list.map do |s|
        s.is_a?(Hash) ? { "url" => s["url"].to_s, "description" => s["description"].to_s.presence } : { "url" => "" }
      end
    end

    # The effective base URL: an explicit override wins, else the first absolute
    # server, else a relative server joined onto the spec's origin, else nil
    # (the user must supply one). Template servers (e.g. `{protocol}://{hostpath}`,
    # common in the *arr specs) carry no concrete host and are skipped.
    def resolved_base_url
      concrete = servers.reject { |s| s["url"].to_s.match?(/[{}]/) }
      absolute = concrete.find { |s| absolute_http?(s["url"]) }
      return absolute["url"].chomp("/") if absolute

      candidate = concrete.find { |s| s["url"].present? }
      return nil unless candidate

      origin = origin_from_source
      return URI.join("#{origin}/", candidate["url"]).to_s.chomp("/") if origin && !absolute_http?(candidate["url"])

      nil
    end

    def origin_from_source
      return nil unless @source_url

      uri = URI(@source_url)
      return nil unless uri.host

      "#{uri.scheme}://#{uri.host}#{":#{uri.port}" unless [ 80, 443 ].include?(uri.port.to_i)}"
    rescue URI::InvalidURIError
      nil
    end

    def absolute_http?(url)
      return false if url.blank?

      uri = URI(url)
      %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end

    # Security schemes declared in `components.securitySchemes` become the
    # credential slots the user fills in after the integration is saved.
    def security_slots
      schemes = raw_schemes || {}
      schemes.each_with_object({}) do |(name, definition), out|
        next unless definition.is_a?(Hash)
        next if %w[mutual_tls tls].include?(definition["type"].to_s)

        out[name] = build_slot(name, definition)
      end
    end

    def raw_schemes
      components = @raw["components"]
      components.is_a?(Hash) ? components["securitySchemes"] : nil
    end

    def build_slot(name, definition)
      token = name.to_s
      case definition["type"].to_s
      when "http"
        if definition["scheme"].to_s.downcase == "basic"
          { "kind" => "basic", "name" => token, "in_desc" => "HTTP Basic" }
        else
          { "kind" => "bearer", "name" => token, "in_desc" => "Authorization: Bearer" }
        end
      when "apiKey"
        { "kind" => "apikey", "name" => token, "param_name" => definition["name"].to_s,
          "in" => definition["in"].to_s.presence || "header", "in_desc" => definition["name"].to_s }
      when "oauth2", "openIdConnect"
        oauth_slot(name, definition) || { "kind" => "bearer", "name" => token, "in_desc" => "OAuth token" }
      else
        { "kind" => "apikey", "name" => token, "param_name" => token.underscore,
          "in" => "header", "in_desc" => token }
      end
    end

    # An OAuth scheme with a usable authorization-code flow (both
    # authorizationUrl and tokenUrl) becomes an `oauth` slot: the service can
    # run the full browser OAuth dance against these endpoints instead of
    # requiring a manually pasted bearer token. Flows without a concrete
    # redirect-style flow (e.g. a bare OIDC `openIdConnectUrl` or implicit
    # flows) degrade to a plain bearer slot — there is no consent URL to drive.
    def oauth_slot(name, definition)
      flows = definition["flows"]
      flow = flows.is_a?(Hash) ? flows["authorizationCode"] : nil
      return nil unless flow.is_a?(Hash)
      return nil if flow["authorizationUrl"].to_s.blank? || flow["tokenUrl"].to_s.blank?

      {
        "kind" => "oauth",
        "name" => name.to_s,
        "in_desc" => "OAuth",
        "authorization_url" => flow["authorizationUrl"].to_s,
        "token_url" => flow["tokenUrl"].to_s,
        "refresh_url" => flow["refreshUrl"].to_s.presence,
        "scopes" => flow["scopes"].is_a?(Hash) ? flow["scopes"] : {}
      }
    end

    def operations
      ids = Set[]
      operation_entries.map do |entry|
        id = entry["operation_id"]
        entry["operation_id"] = ids.add?(id).nil? ? "#{id}_#{entry["path"].to_s.split('/').compact_blank.last}" : id
        {
          "method" => entry["method"],
          "path" => entry["path"],
          "operation_id" => entry["operation_id"],
          "name" => entry["name"],
          "summary" => entry["summary"],
          "description" => entry["description"],
          "tags" => entry["tags"],
          "security" => entry["security"],
          "security_requirements" => entry["security_requirements"],
          "args_schema" => entry["args_schema"],
          "body" => entry["body"],
          "response_fields" => entry["response_fields"]
        }
      end
    end

    def operation_entries
      @operation_entries ||= @root.paths.path.flat_map do |path_key, item|
        HTTP_METHODS.filter_map do |method|
          op = item.send(method)
          next unless op

          {
            "method" => method.to_s.upcase,
            "path" => path_key,
            "operation_id" => op.operation_id.to_s,
            "name" => fallback_operation_name(method, path_key, op.operation_id.to_s.presence),
            "summary" => op.summary.to_s.strip,
            "description" => (op.description.to_s.presence || op.summary.to_s).strip,
            "tags" => Array(op.tags),
            "security" => effective_security(op),
            "security_requirements" => effective_security_requirements(op),
            "args_schema" => args_schema(op, path_key),
            "body" => body_info(op),
            "response_fields" => response_fields(op)
          }
        end
      end
    end

    def effective_security(op)
      declared = op.raw_schema["security"]
      declared = declared.is_a?(Array) ? declared : global_security
      (declared || []).flat_map { |requirement| requirement.is_a?(Hash) ? requirement.keys : [] }.presence || []
    end

    # Per-operation security requirements with their OAuth scopes preserved:
    # [{ "scheme" => "OAuth2", "scopes" => ["file_content:read", ...] }, ...].
    # Operations may offer several security alternatives (e.g. Figma:
    # PersonalAccessToken | PlanAccessToken | OAuth2:[scopes]); the scope
    # lists let an OAuth-backed service instance filter its tools to what its
    # credential's configured scopes can actually do.
    def effective_security_requirements(op)
      declared = op.raw_schema["security"]
      declared = declared.is_a?(Array) ? declared : global_security
      (declared || []).each_with_object([]) do |requirement, out|
        next unless requirement.is_a?(Hash)

        requirement.each do |scheme, scopes|
          out << { "scheme" => scheme.to_s, "scopes" => Array(scopes).map(&:to_s) }
        end
      end
    end

    def global_security
      @raw["security"].is_a?(Array) ? @raw["security"] : []
    end

    def body_info(op)
      request_body = op.request_body
      return nil unless request_body

      { "required" => request_body.required == true, "content_types" => Array(request_body.content.keys) }
    end

    # Candidate identity-field paths from the operation's success JSON response
    # (top-level scalars plus one level of array/object wrappers), used by the
    # wizard's health-check identity picker. Bounded and best-effort.
    def response_fields(op)
      responses = op.responses
      return [] unless responses

      success = responses.response&.find { |code, _| code.to_s.start_with?("2") }
      success = success&.last || responses.default
      return [] unless success

      media = success.content&.values&.first
      schema = media&.schema
      return [] unless schema

      field_paths(schema, nil, 0).first(24)
    end

    def field_paths(schema, prefix, depth)
      return [] unless schema && depth <= 2

      props = schema.properties
      return [] unless props

      props.flat_map do |key, prop|
        path = [ prefix, key ].compact.join(".")
        case prop.type
        when "object"
          field_paths(prop, path, depth + 1)
        when "array"
          child = prop.items
          if child.is_a?(OpenAPIParser::Schemas::Schema) && child.type == "object" && child.properties.present?
            child.properties.keys.map { |child_key| "#{path}[0].#{child_key}" }
          else
            [ path ]
          end
        else
          [ path ]
        end
      end
    end

    def args_schema(op, path_key)
      props = {}
      required = []

      parameters(op, path_key).each do |param|
        next unless param

        name = param["name"].to_s
        next if name.blank?

        props[name] = {
          "type" => param_type(param["schema"]),
          "description" => param["description"].to_s.presence,
          "x-in" => param["in"].to_s
        }
        required << name if param["required"] == true
      end

      append_body_args(op, props, required)

      { "type" => "object", "properties" => props, "required" => required.uniq }
    end

    # Path + query + header parameters from the operation, with path-level
    # parameters merged in when the operation inherits them from the PathItem.
    def parameters(op, path_key)
      explicit = Array(op.parameters).map { |param| parameter_info(param) }
      names = explicit.map { |param| param && param["name"] }
      inherited = raw_path_parameters(path_key).reject { |param| names.include?(param["name"]) }
      explicit.compact + inherited
    end

    def parameter_info(param)
      return nil unless param

      {
        "name" => param.name.to_s,
        "in" => param.in.to_s,
        "required" => param.required == true,
        "description" => param.description.to_s.presence,
        "schema" => compact_schema(param.schema)
      }
    end

    def raw_path_parameters(path_key)
      item = @root.paths.path[path_key]
      raw = item&.raw_schema
      return [] unless raw.is_a?(Hash)

      Array(raw["parameters"]).filter_map do |param|
        next unless param.is_a?(Hash)

        {
          "name" => param["name"].to_s,
          "in" => param["in"].to_s,
          "required" => param["required"] == true,
          "description" => param["description"].to_s.presence,
          "schema" => compact_schema_hash(param["schema"])
        }
      end
    end

    # JSON request bodies are surfaced as one MCP arg per top-level object
    # property (so the caller passes `albumId`, `assetId`, ...). Non-object
    # bodies degrade to a single `body` arg.
    def append_body_args(op, props, required)
      request_body = op.request_body
      content = request_body&.content || {}
      media = content["application/json"] || content.values.first
      return unless media

      schema = media.schema
      return unless schema

      if schema.type == "object" && schema.properties.present?
        body_required = Array(schema.raw_schema["required"]).map(&:to_s)
        schema.properties.each do |prop_key, prop_schema_obj|
          next unless prop_schema_obj.is_a?(OpenAPIParser::Schemas::Schema)

          props[prop_key.to_s] = {
            "type" => param_type(compact_schema(prop_schema_obj)),
            "description" => prop_schema_obj.description.to_s.presence,
            "x-in" => "body",
            "x-body-key" => prop_key.to_s
          }
          required << prop_key.to_s if request_body.required && body_required.include?(prop_key.to_s)
        end
      else
        props["body"] = {
          "type" => param_type({ "type" => schema.type }),
          "x-in" => "body",
          "x-body-raw" => true,
          "description" => "Request body"
        }
        required << "body" if request_body.required
      end
    end

    def compact_schema(schema)
      return {} unless schema

      out = {}
      out["type"] = schema.type if schema.type.present?
      raw = schema.raw_schema
      out["enum"] = raw["enum"] if raw.is_a?(Hash) && raw["enum"].is_a?(Array)
      out
    end

    def compact_schema_hash(hash)
      return {} unless hash.is_a?(Hash)

      out = {}
      out["type"] = hash["type"] if hash["type"].is_a?(String)
      out["enum"] = hash["enum"] if hash["enum"].is_a?(Array)
      out
    end

    def param_type(schema)
      schema = schema.is_a?(Hash) ? schema : {}
      case schema["type"]
      when "integer", "number" then "number"
      when "boolean" then "boolean"
      when "array" then "array"
      when "object" then "object"
      when "string" then "string"
      else "string"
      end
    end

    def tags
      operation_entries.flat_map { |entry| entry["tags"] }.uniq
    end

    def slugify(text)
      text.to_s
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .gsub(/[^a-zA-Z0-9]+/, "_")
        .gsub(/\A_+|_+\z/, "")
        .downcase
    end

    # The operation's slugged identifier. Prefers a declared operationId; when
    # the spec has none (e.g. the *arr family), falls back to slugging the
    # method + path. In that fallback a leading API-version prefix
    # (`/api/v1/...`, `/api/v3/...`) is stripped so tool names like
    # `prowlarr_get_api_v1_search` become `prowlarr_get_search` — the version is
    # noise, not part of the operation's identity.
    def fallback_operation_name(method, path_key, operation_id)
      return slugify(operation_id) if operation_id.present?

      stripped = path_key.to_s.sub(%r{\A/api/v\d+/}, "")
      slugify("#{method}/#{stripped}").presence || "operation"
    end
  end
end
