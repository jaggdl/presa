# frozen_string_literal: true

require "base64"
require "faraday"
require "json"

module Services
  # A service generated from an OpenAPI 3.x document. Adding a spec creates an
  # `OpenapiKind` (the definition stored once per team+namespace); each
  # *service* of that kind is an instance row here referencing the kind, with
  # its own name, base URL override, and connected credentials in its encrypted
  # `config`. The kind's namespace is the machine kind (e.g. "immich"), so the
  # service rows read as first-class instances of a first-class kind.
  #
  # There is no static `openapi` picker card. Instead each `OpenapiKind` gets a
  # dynamic (anonymous) subclass of this class — one per namespace, configured
  # via `Service`'s class DSL (kind/display name/description) — so the existing
  # services index, search, and new/create flows work unchanged. Instances are
  # still persisted as `Services::Openapi` (single STI type) and find their
  # kind through `openapi_kind_id`.
  #
  # Credentials for the spec's security schemes live in `config` under `cred_*`
  # keys and are per-service; the credential *slots* themselves come from the
  # kind, so multiple services of a kind share a form but keep independent
  # secrets.
  class Openapi < Service
    DISCOVERY_TTL = 5.minutes

    belongs_to :openapi_kind, optional: true, inverse_of: :services

    validate :spec_present
    validate :base_url_is_http

    # Wire new instances up to their kind when created through a dynamic
    # (virtual) kind class, so `klass.new` in the service form carries the kind
    # without needing the foreign key passed explicitly.
    def initialize(*)
      super
      if self.class.respond_to?(:openapi_kind) && self.class.openapi_kind.present?
        self.openapi_kind ||= self.class.openapi_kind
      end
    end

    class << self
      # Namespaces of every registered OpenAPI kind — appended to
      # `Service.kinds` so they show up in the picker alongside static kinds.
      def virtual_kinds
        OpenapiKind.order(:namespace).pluck(:namespace)
      rescue ActiveRecord::StatementInvalid
        []
      end

      # The dynamic service class backing the given kind namespace, or nil.
      # An anonymous subclass keeps instances as plain `Services::Openapi` STI
      # rows while providing the class DSL (config_kind/config_display_name/
      # description) the picker/search/form flows depend on.
      def virtual_class_for(namespace)
        kind = OpenapiKind.find_by(namespace: namespace)
        return nil unless kind

        virtual_classes[namespace.to_s] ||= build_virtual_class(kind)
      end

      # Credential slots (field => opts) for a kind: one secret per security
      # scheme plus one per "add a method" extra credential. Values are stored
      # per service in `config` under these keys.
      def credential_schema(kind)
        fields = {}
        kind.security_slots.each do |name, _slot|
          fields["cred_#{scheme_key(name)}"] = { "required" => false, "secret" => true }
        end
        kind.extra_credentials.each do |credential|
          fields[credential["cred_key"].to_s] = { "required" => false, "secret" => true }
        end
        fields.transform_keys(&:to_s)
      end

      def scheme_key(name)
        name.to_s.strip.underscore.gsub(/[^a-z0-9_]/i, "_").gsub(/_{2,}/, "_")
            .gsub(/\A_+|_+\z/, "").presence || "scheme"
      end

      private

      def virtual_classes
        @virtual_classes ||= {}
      end

      def build_virtual_class(kind)
        Class.new(self).tap do |klass|
          klass.config_kind = kind.namespace
          klass.config_display_name = kind.title
          klass.config_category = :general
          klass.class_attribute :openapi_kind, default: kind
          klass.define_singleton_method(:description) { openapi_kind&.description }
        end
      end
    end

    # Credential fields are derived per instance from the kind's security
    # schemes (plus any "add a method" extra credentials). The class's
    # `config_fields` stays empty, so only the credential slots render in the
    # per-service form (alongside the OpenAPI-specific base URL / health
    # pickers). Pre-kind rows derive the same slots from their own config spec.
    def config_schema
      if openapi_kind
        self.class.credential_schema(openapi_kind)
      else
        fields = {}
        security_slots.each do |name, _slot|
          fields["cred_#{scheme_key(name)}"] = { "required" => false, "secret" => true }
        end
        extra_credentials.each do |credential|
          fields[credential["cred_key"].to_s] = { "required" => false, "secret" => true }
        end
        fields.transform_keys(&:to_s)
      end
    end

    # The instance-level machine kind: the kind's namespace (tool prefix).
    def kind
      namespace
    end

    def display_name
      api_title.presence || super
    end

    # The kind's spec-derived description (cards/show header); legacy rows fall
    # back to the class-level docs description.
    def description
      openapi_kind&.description || super
    end

    # The parsed definition, owned by the kind (legacy rows fall back to a spec
    # embedded in their own config).
    def definition
      (openapi_kind&.definition).presence || config_spec.presence || {}
    end
    alias spec_definition definition

    def namespace
      openapi_kind&.namespace.presence || config[:namespace].to_s.presence || definition["namespace_slug"].to_s.presence || "openapi"
    end

    def api_title
      openapi_kind&.title.presence || config[:title].to_s.presence || definition["title"].to_s.presence
    end

    def api_version
      definition["version"].to_s
    end

    def spec_url
      openapi_kind&.spec_url.presence || config[:spec_url].to_s.presence
    end

    def base_url
      config[:base_url].to_s.presence || openapi_kind&.base_url
    end

    def source
      definition["source"].to_s.presence
    end

    def operation_count
      definition["operation_count"].to_i
    end

    def tag_count
      definition["tag_count"].to_i
    end

    # Security scheme slots: { scheme_name => {kind,name,param_name,in,in_desc} }.
    def security_slots
      security = definition["security"]
      security.is_a?(Hash) ? security : {}
    end

    # Extra "add a method"-style credentials: [{name,in,param_name,cred_key}].
    # Their *definitions* live on the kind (shared by every service); their
    # *values* are per-service under the matching `cred_key` in `config`.
    def extra_credentials
      list = (openapi_kind && openapi_kind.extra_credentials.presence) || config[:extra_credentials]
      list.is_a?(Array) ? list : []
    end

    def operations
      list = definition["operations"]
      list.is_a?(Array) ? list : []
    end

    def operation(operation_id)
      operations.find { |op| op["operation_id"].to_s == operation_id.to_s }
    end

    def health_check_operation
      config[:health_op].to_s.presence || openapi_kind&.health_op
    end

    # The set of credential keys the spec's schemes use (for display).
    def credential_keys
      security_slots.keys.map { |name| "cred_#{scheme_key(name)}" } +
        extra_credentials.map { |c| c["cred_key"].to_s }
    end

    # Single-credential authentication inferred from the spec's security schemes.
    # The *options* (type + transmission details) come from the security slots
    # the kind's spec declares — never free-form; only the value (and possibly
    # which option) is chosen per service. If the spec declares exactly one
    # scheme the choice disappears entirely.
    def credential_type
      config[:cred_type].to_s.presence || credential_type_candidates.first.then { |c| c && c[:type] }
    end

    def credential_name
      config[:cred_name].to_s.presence || credential_type_candidates.find { |c| c[:type] == credential_type }&.dig(:name)
    end

    def credential_value
      config[:cred_value].to_s.presence
    end

    # Distinct transmission options derived from the spec's security schemes:
    # [{ type:, name:, label: }]. `name` is the header/query/cookie name for
    # API-key-style schemes (nil for bearer/basic).
    def credential_type_candidates
      security_slots.each_value.filter_map { |slot| candidate_for_slot(slot) }.uniq
    end

    def primary_credential_candidate
      credential_type_candidates.first
    end

    def candidate_for_slot(slot)
      case slot["kind"].to_s
      when "basic"
        { type: "basic", name: nil, label: "HTTP Basic — Authorization: Basic user:password" }
      when "apikey"
        name = slot["param_name"].to_s.presence || slot["name"].to_s
        case slot["in"].to_s
        when "query"
          { type: "apikey_query", name: name, label: "API key — #{name} query parameter" }
        when "cookie"
          { type: "cookie", name: name, label: "Cookie — #{name}" }
        else
          { type: "apikey_header", name: name, label: "API key — #{name} header" }
        end
      else
        { type: "bearer", name: nil, label: "Bearer token — Authorization: Bearer <token>" }
      end
    end

    # Descriptor list for the generated tools: [{name, description, inputSchema}].
    # Mirrors `Mcp#remote_tools`, cached per spec content.
    def openapi_tools
      cache_key = [ "openapi_tools", (openapi_kind&.definition || config_spec).hash ]
      Rails.cache.fetch(cache_key, expires_in: DISCOVERY_TTL) do
        operations.filter_map do |op|
          next if op["operation_id"] == health_check_operation

          {
            "name" => "#{namespace}_#{op["name"]}",
            "description" => tool_description(op),
            "inputSchema" => op["args_schema"] || {}
          }
        end
      end
    end

    def execute_operation(operation, arguments)
      raise "No operation to execute" unless operation

      args = arguments.to_h.with_indifferent_access
      path = "#{base_path}#{render_path(operation["path"], args)}"
      query, headers, cookies, body, content_type = build_request(operation, args)

      response = client.run_request(operation["method"].downcase.to_sym, path, body, headers) do |req|
        req.params.update(query) if query.any?
        if cookies.any?
          req.headers["Cookie"] = cookies.map { |k, v| "#{k}=#{v}" }.join("; ")
        end
        req.headers["Content-Type"] = content_type if content_type
      end

      success?(response) ? response.body : error_payload(response)
    rescue StandardError => e
      raise e if e.is_a?(::Openapi::ApiError) || e.is_a?(ArgumentError)

      { "error" => e.message }
    end

    def test_connection(config = nil)
      # Submitted form config overrides the stored config (credentials, health
      # fields) but keeps base_url/spec/namespace intact for the probe.
      submitted = normalize_config(config)
      cfg = normalize_config(self.config).merge(submitted)

      operation_id = cfg[:health_op].to_s.presence || health_check_operation

      unless operation_id.present?
        validate_required_credentials!(cfg)
        return true
      end

      op = operation(operation_id)
      raise "Health check operation is no longer available" unless op

      validate_operation_credentials!(op, cfg)
      response = run_with(cfg, op, {})
      status = response.is_a?(Hash) && response["error"] ? false : true
      raise response["error"].to_s unless status

      true
    end

    # Builds the outbound HTTP client against the base URL's origin; a base URL
    # with a path prefix (e.g. "https://host/api") is split so the path is
    # re-prefixed per request (Faraday otherwise drops a base's trailing path).
    def client
      base_url_config = base_url
      raise "Base URL is not configured for this OpenAPI integration" if base_url_config.blank?

      uri = URI(base_url_config)
      raise "Base URL must be http(s)" unless %w[http https].include?(uri.scheme)

      origin = "#{uri.scheme}://#{uri.host}"
      origin += ":#{uri.port}" unless [ 80, 443 ].include?(uri.port.to_i)
      @client ||= Faraday.new(url: origin) do |faraday|
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 30
        faraday.options.open_timeout = 10
      end
    rescue URI::InvalidURIError
      raise "Base URL is invalid"
    end

    def base_path
      uri = URI(base_url.to_s)
      uri.path.to_s.chomp("/")
    end

    private

    def spec_present
      errors.add(:config, "spec is missing") if definition.empty?
    end

    def base_url_is_http
      return if base_url.blank?

      uri = URI(base_url)
      unless %w[http https].include?(uri.scheme)
        errors.add(:config, "base URL must be http(s)")
      end
    rescue URI::InvalidURIError
      errors.add(:config, "base URL is invalid")
    end

    # Backward-compat read of a spec embedded in the service's own config
    # (pre-kind rows). New instances always resolve the definition via the kind.
    def config_spec
      raw = config[:spec]
      raw.is_a?(Hash) ? raw : {}
    end

    def tool_description(op)
      summary = op["summary"].to_s.presence
      summary.presence || "#{op["method"]} #{op["path"]}"
    end

    # Constructs the HTTP pieces for an operation from the caller's MCP args:
    # a path with `{params}` substituted, query/header params, auth credentials,
    # and (for JSON request bodies) a reconstructed object.
    def build_request(op, args)
      query = {}
      headers = {}
      cookies = {}
      body = nil
      content_type = nil

      op_args(op).each do |arg|
        key = arg_key(arg)
        next unless args.key?(key)

        value = args[key]
        case arg["x-in"].to_s
        when "query"
          query[arg["name"]] = query_style_value(arg, value)
        when "header"
          headers[arg["name"]] = value.to_s
        when "cookie"
          cookies[arg["name"]] = value.to_s
        end
      end

      apply_auth(op, query, headers, cookies)
      apply_extra_credentials(query, headers, cookies, args)

      if (body_info = op["body"])
        body, content_type = build_body(op, body_info, args)
      end

      [ query, headers, cookies, body, content_type ]
    end

    def op_args(op)
      ops = op["args_schema"]
      return [] unless ops.is_a?(Hash)

      (ops["properties"] || {}).map do |key, meta|
        (meta || {}).reverse_merge("name" => key.to_s)
      end
    end

    def arg_key(arg)
      arg["name"].to_s
    end

    def query_style_value(arg, value)
      value.is_a?(Array) ? value.join(",") : value
    end

    # Applies the operation's declared security schemes. A single per-service
    # credential (type chooser + value) covers the request when set; otherwise
    # the legacy per-scheme slots are tried in order (first present wins).
    def apply_auth(op, query, headers, cookies)
      value = credential_value
      if value.present?
        apply_credential_type(credential_type, value, query, headers, cookies)
        return
      end

      op["security"].to_a.each do |scheme_name|
        slot = security_slots[scheme_name.to_s]
        next unless slot

        value = legacy_credential_value(scheme_name)
        next if value.blank?

        apply_slot(slot, value, query, headers, cookies)
      end
    end

    # Maps the chosen credential type to an outbound header/query/cookie.
    def apply_credential_type(type, value, query, headers, cookies)
      case type.to_s
      when "basic"
        headers["Authorization"] = "Basic #{Base64.strict_encode64(value.to_s)}"
      when "apikey_header"
        headers[credential_name.presence || "X-API-Key"] = value
      when "apikey_query"
        query[credential_name.presence || "api_key"] = value
      when "cookie"
        cookies[credential_name.presence || "token"] = value
      else
        headers["Authorization"] = "Bearer #{value}"
      end
    end

    # Extra "add a method" credentials apply to every operation.
    def apply_extra_credentials(query, headers, cookies, _args = {})
      extra_credentials.each do |credential|
        value = config[credential["cred_key"].to_sym]
        next if value.blank?

        location = credential["in"].to_s.presence || "header"
        param_name = credential["param_name"].to_s.presence || credential["name"].to_s
        apply_slot_location(location, param_name, value.to_s, query, headers, cookies)
      end
    end

    def legacy_credential_value(scheme_name)
      config[:"cred_#{scheme_key(scheme_name)}"]
    end

    def apply_slot(slot, value, query, headers, cookies)
      case slot["kind"].to_s
      when "basic"
        headers["Authorization"] = "Basic #{Base64.strict_encode64(value.to_s)}"
      when "apikey"
        location = slot["in"].to_s
        param_name = slot["param_name"].to_s.presence || slot["name"].to_s
        apply_slot_location(location, param_name, value.to_s, query, headers, cookies)
      else
        headers["Authorization"] = "Bearer #{value}"
      end
    end

    def apply_slot_location(location, param_name, value, query, headers, cookies)
      case location
      when "query"
        query[param_name] = value
      when "cookie"
        cookies[param_name] = value
      when "header"
        headers[param_name] = value
      end
    end

    # Reconstructs the JSON request body from the flattened body args, or passes
    # a raw body arg through untouched.
    def build_body(op, body_info, args)
      content_type = pick_content_type(body_info["content_types"])
      body_props = op_args(op).select { |arg| arg["x-in"].to_s == "body" }

      if body_props.any? { |arg| arg["x-body-raw"] }
        arg = body_props.first
        key = arg_key(arg)
        return [ args.key?(key) ? convert_raw_body(args[key], content_type) : nil, content_type ]
      end

      object = {}
      body_props.each do |arg|
        key = arg_key(arg)
        next unless args.key?(key)

        body_key = arg["x-body-key"].to_s.presence || key
        object[body_key] = coerce_value(args[key])
      end
      [ object.any? ? JSON.generate(object) : nil, content_type ]
    end

    def pick_content_type(list)
      array = Array(list)
      array.find { |ct| ct.include?("json") } || array.first || "application/json"
    end

    def convert_raw_body(value, content_type)
      if content_type.to_s.include?("json") && value.is_a?(String)
        begin
          return JSON.parse(value)
        rescue JSON::ParserError
          nil
        end
      end
      value
    end

    def coerce_value(value)
      case value
      when String
        return value unless value =~ /\A[\[{]/
        begin
          JSON.parse(value)
        rescue JSON::ParserError
          value
        end
      else
        value
      end
    end

    def render_path(path, args)
      path.gsub(/\{([^}]+)\}/) do
        name = Regexp.last_match(1)
        value = args[name]
        raise ArgumentError, "Missing required path parameter: #{name}" if value.nil?

        URI.encode_www_form_component(value.to_s).gsub("%2F", "/")
      end
    end

    # Runs an operation against an explicit config (used by `test_connection`).
    def run_with(cfg, op, args)
      # Temporarily swap the config so credential lookup reads the form values.
      original = config
      self.config = cfg
      execute_operation(op, args)
    ensure
      self.config = original if original
    end

    def validate_required_credentials!(cfg)
      # Single-credential path (spec declares schemes the user fills via
      # cred_type/cred_value on the form): only the value must be present.
      if credential_type_candidates.any?
        raise "Credential value is required" if cfg[:cred_value].to_s.blank?
        return
      end

      missing = credential_keys.select { |key| cfg[key.to_sym].blank? }
      return if missing.empty?

      raise "#{missing.map(&:humanize).join(", ")} #{missing.one? ? "is" : "are"} required"
    end

    def validate_operation_credentials!(op, cfg)
      return if op["security"].to_a.empty?

      # Any spec-declared scheme is satisfied by the single credential.
      if credential_type_candidates.any?
        raise "Credential value is required to run #{op["operation_id"]}" if cfg[:cred_value].to_s.blank?
        return
      end

      missing = op["security"].to_a.filter_map do |scheme_name|
        key = "cred_#{scheme_key(scheme_name)}"
        key if cfg[key.to_sym].blank?
      end
      return if missing.empty?

      raise "#{missing.map(&:humanize).join(", ")} #{missing.one? ? "is" : "are"} required to run #{op["operation_id"]}"
    end

    def success?(response)
      response.status.to_i >= 200 && response.status.to_i < 300
    end

    def error_payload(response)
      body = response.body
      detail = case body
      when Hash then body["message"].presence || body["error"].presence || body.to_s
      when String then body.strip[0, 300]
      else body.to_s
      end
      { "error" => "#{response.status}: #{detail.presence || "no response body"}" }
    end

    def scheme_key(name)
      self.class.scheme_key(name)
    end
  end
end
