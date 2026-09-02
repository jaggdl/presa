# frozen_string_literal: true

module Openapi
  # Converts an `OpenAPIParser::Schemas::Schema` (or raw Hash) into a compact
  # JSON Schema object used both for the generated tool's input schema (MCP
  # listing) and for the persisted per-operation metadata. Defensive by design:
  # a spec's schema subtree is best-effort — deeply nested or recursive
  # structures degrade to `{}` (accept anything) rather than erroring.
  class SchemaBuilder
    MAX_DEPTH = 8
    MAX_PROPERTIES = 60
    MAX_NODES = 400

    attr_reader :visited, :depth, :nodes

    def initialize
      @visited = {}.compare_by_identity
      @depth = 0
      @nodes = 0
    end

    # Builds a JSON Schema hash from an OpenAPI `Schema` object or raw Hash.
    # Returns `{}` (any value) when given nil, a Reference, or content too deep.
    def build(schema)
      @visited = {}.compare_by_identity
      @depth = 0
      @nodes = 0
      convert(schema)
    end

    private

    def convert(node)
      return {} if node.nil?
      return {} unless node.is_a?(OpenAPIParser::Schemas::Schema)
      return {} if @nodes >= MAX_NODES
      return {} if @visited[node]

      @visited[node] = true
      @nodes += 1
      @depth += 1

      out = if @depth > MAX_DEPTH
        {}
      else
        convert_schema(node)
      end

      @depth -= 1
      out
    end

    def convert_schema(schema)
      type = normalize_type(schema.type)

      if type == "array"
        items_schema = schema.items || OpenAPIParser::Schemas::Schema.new(schema.object_reference, schema, schema.root, {})
        return base_out(schema).merge("type" => "array", "items" => convert(items_schema))
      end

      return union_schema(schema, "oneOf") if schema.raw_schema.key?("oneOf")
      return union_schema(schema, "anyOf") if schema.raw_schema.key?("anyOf")
      return merge_all_of(schema) if schema.raw_schema.key?("allOf")

      base = base_out(schema)
      if type == "object"
        base["type"] = "object"
        props = properties(schema)
        base["properties"] = props unless props.empty?
        required = Array(schema.raw_schema["required"]).map(&:to_s).select { |k| props.key?(k) }
        base["required"] = required unless required.empty?
        base["additionalProperties"] = false if schema.additional_properties == false
      else
        base["type"] = type if type
        base["format"] = schema.format if schema.format.presence
      end
      base
    end

    # Merges the property maps of an `allOf` list into a single object schema.
    def merge_all_of(schema)
      base = base_out(schema)
      props = {}
      required = []
      Array(schema.all_of).each do |variant|
        merged = convert(variant)
        (merged["properties"] || {}).each { |k, v| props[key_name(k)] = v }
        required.concat(Array(merged["required"]))
      end
      base["type"] = "object"
      base["properties"] = props unless props.empty?
      base["required"] = required.uniq unless required.empty?
      base
    end

    def union_schema(schema, key)
      base = base_out(schema)
      base["anyOf"] = Array(schema.raw_schema[key]).map do |variant|
        v = variant.is_a?(OpenAPIParser::Schemas::Reference) ? schema.root&.find_object(variant.ref) : variant
        convert(v)
      end
      base
    end

    # Handles object properties, resolved through openapi_parser (refs expanded).
    def properties(schema)
      raw_props = schema.properties || {}
      raw_props.values.first(MAX_PROPERTIES).each_with_object({}) do |prop, acc|
        acc[prop.object_reference.to_s.split("/").last] ||= convert(prop)
      end
    end

    def base_out(schema)
      out = {}
      out["description"] = schema.description if schema.description.presence
      if schema.raw_schema.is_a?(Hash)
        out["enum"] = schema.raw_schema["enum"] if schema.raw_schema["enum"].is_a?(Array)
        out["default"] = schema.raw_schema["default"] if schema.raw_schema.key?("default")
        out["nullable"] = true if schema.raw_schema["nullable"] == true
      end
      out
    end

    def normalize_type(type)
      return nil if type.nil?
      return type unless type.is_a?(Array)

      type.find { |t| t != "null" }
    end

    def key_name(key)
      key.to_s
    end
  end
end