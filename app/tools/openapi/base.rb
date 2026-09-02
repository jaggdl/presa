# frozen_string_literal: true

require "json"

module Openapi
  # Abstract base for tools generated from an OpenAPI document. Never exposed
  # directly: `ApplicationTool.expose_for` builds a concrete subclass per
  # operation (~like `Mcp::Base` for remote MCP tools), carrying the operation's
  # name, description, and argument schema. Argument validation is left
  # permissive (fast-mcp's default passthrough schema); the operation's schema
  # is surfaced for listing via `input_schema_to_json`.
  class Base < ApplicationTool
    service_kind :openapi
    abstract_tool true

    class_attribute :remote_tool_name, default: nil
    class_attribute :remote_input_schema, default: {}
    class_attribute :remote_openapi_operation, default: nil

    def call(**args)
      service.execute_operation(self.class.remote_openapi_operation, args)
    end

    # Surface the operation's argument schema verbatim so MCP clients know what
    # arguments to send.
    def self.input_schema_to_json
      schema = remote_input_schema
      return JSON.parse(schema) if schema.is_a?(String)

      schema.with_indifferent_access.slice(:type, :properties, :required)
    end
  end
end