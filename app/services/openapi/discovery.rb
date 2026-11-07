# frozen_string_literal: true

module Openapi
  # Converts a Google Discovery document into an OpenAPI 3.0 document so the
  # existing parser/generator pipeline can consume APIs that publish discovery
  # only — notably the Google Ads API, which ships no upstream OpenAPI document
  # (and is absent from apis.guru), so its preset points `spec_url` straight at
  # `https://googleads.googleapis.com/$discovery/rest?version=v26`.
  #
  # The conversion is mechanical: discovery's `resources`/`methods` map onto
  # OpenAPI paths/operations, `schemas` onto `components.schemas` (bare `$ref`
  # names rewritten to `#/components/schemas/...`), and the `auth.oauth2.scopes`
  # block onto an `oauth2` authorization-code scheme. Discovery carries no
  # OAuth endpoints, so Google's are supplied as the default.
  module Discovery
    GOOGLE_AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"

    SCHEMA_KEYS = %w[type format description enum default minimum maximum
                     pattern required title readOnly].freeze
    PARAM_KEYS = %w[type format enum default minimum maximum pattern].freeze

    class << self
      # True for a Google Discovery document (`discovery#restDescription`).
      def discovery?(raw)
        return false unless raw.is_a?(Hash)

        raw["kind"].to_s == "discovery#restDescription" || raw["discoveryVersion"].present?
      end

      # Returns an OpenAPI 3.0.3 hash equivalent to the discovery document.
      def to_openapi(raw)
        {
          "openapi" => "3.0.3",
          "info" => info(raw),
          "servers" => servers(raw),
          "security" => security(raw),
          "components" => {
            "securitySchemes" => security_schemes(raw),
            "schemas" => schemas(raw)
          },
          "paths" => paths(raw)
        }
      end

      private

      def info(raw)
        {
          "title" => raw["title"].to_s.presence || raw["name"].to_s.presence || "Untitled API",
          "version" => raw["version"].to_s,
          "description" => raw["description"].to_s
        }
      end

      def servers(raw)
        url = raw["rootUrl"].to_s.presence
        url ? [ { "url" => url.chomp("/") } ] : []
      end

      # The OAuth scope definitions discovery declares under `auth.oauth2`.
      def scopes(raw)
        raw.dig("auth", "oauth2", "scopes").then { |s| s.is_a?(Hash) ? s : {} }
      end

      def security(raw)
        keys = scopes(raw).keys
        keys.any? ? [ { "oauth2" => keys } ] : []
      end

      def security_schemes(raw)
        return {} if scopes(raw).empty?

        {
          "oauth2" => {
            "type" => "oauth2",
            "description" => "OAuth 2.0 authorization-code flow. Register an OAuth client " \
                             "and authorize the scopes this API requires.",
            "flows" => {
              "authorizationCode" => {
                "authorizationUrl" => GOOGLE_AUTHORIZE_URL,
                "tokenUrl" => GOOGLE_TOKEN_URL,
                "scopes" => scopes(raw)
              }
            }
          }
        }
      end

      def schemas(raw)
        list = raw["schemas"].is_a?(Hash) ? raw["schemas"] : {}
        list.each_with_object({}) { |(name, schema), out| out[name] = convert_schema(schema) }
      end

      def convert_schema(schema)
        case schema
        when Array then schema.map { |item| convert_schema(item) }
        when Hash then convert_schema_hash(schema)
        else schema
        end
      end

      def convert_schema_hash(schema)
        out = {}
        out["$ref"] = ref(schema["$ref"]) if schema["$ref"]
        SCHEMA_KEYS.each { |key| out[key] = schema[key] if schema.key?(key) }
        out["items"] = convert_schema(schema["items"]) if schema.key?("items")
        if schema["properties"].is_a?(Hash)
          out["properties"] = schema["properties"].transform_values { |value| convert_schema(value) }
        end
        if schema.key?("additionalProperties")
          out["additionalProperties"] = convert_schema(schema["additionalProperties"])
        end
        out
      end

      def ref(name)
        "#/components/schemas/#{name}"
      end

      def paths(raw)
        raw["resources"].is_a?(Hash) ? walk_resources(raw["resources"]) : {}
      end

      def walk_resources(resources, out = {})
        resources.each do |tag, resource|
          next unless resource.is_a?(Hash)

          (resource["methods"] || {}).each { |_name, method| add_operation(out, tag, method) }
          walk_resources(resource["resources"], out) if resource["resources"].is_a?(Hash)
        end
        out
      end

      def add_operation(out, tag, method)
        return unless method.is_a?(Hash)

        path = "/#{method["path"]}"
        verb = method["httpMethod"].to_s.downcase
        return if method["path"].blank? || verb.blank?

        op = {
          "operationId" => method["id"].to_s,
          "summary" => method["summary"].to_s.strip.presence || method["id"].to_s,
          "description" => (method["description"].to_s.presence || method["summary"].to_s).strip,
          "tags" => [ tag ]
        }
        params = operation_parameters(method)
        op["parameters"] = params if params.any?
        op["requestBody"] = request_body(method) if method["request"]
        op["responses"] = responses(method)
        (out[path] ||= {})[verb] = op
      end

      def operation_parameters(method)
        params = method["parameters"]
        return [] unless params.is_a?(Hash)

        # The parameter's name is the map key; discovery objects carry no
        # `name`/`id` field.
        params.filter_map { |name, param| convert_parameter(name, param) }
      end

      def convert_parameter(name, param)
        return nil unless param.is_a?(Hash)

        name = (param["id"].presence || param["name"].presence || name).to_s
        return nil if name.blank?

        out = { "name" => name, "in" => param["location"].to_s.presence || "query" }
        out["description"] = param["description"] if param["description"].present?
        out["required"] = param["required"] if param.key?("required")
        out["schema"] = parameter_schema(param)
        out
      end

      def parameter_schema(param)
        return { "$ref" => ref(param["$ref"]) } if param["$ref"]

        PARAM_KEYS.each_with_object({}) { |key, out| out[key] = param[key] if param.key?(key) }
      end

      def request_body(method)
        request = method["request"]
        schema = request["$ref"] ? { "$ref" => ref(request["$ref"]) } : {}
        { "required" => true, "content" => { "application/json" => { "schema" => schema } } }
      end

      def responses(method)
        response = method["response"]
        entry = { "description" => "Successful response" }
        if response && response["$ref"]
          entry["content"] = { "application/json" => { "schema" => { "$ref" => ref(response["$ref"]) } } }
        end
        { "200" => entry }
      end
    end
  end
end
