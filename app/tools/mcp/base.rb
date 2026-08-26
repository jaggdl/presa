# frozen_string_literal: true

require "json"

module Mcp
  # Abstract base for tools that proxy a remote MCP server. Never exposed
  # directly: `ApplicationTool.expose_for` builds a concrete subclass per
  # remote tool discovered from the service's MCP endpoint, carrying the
  # remote tool's name and description.
  #
  # Input validation is intentionally left permissive (fast-mcp's default
  # passthrough Dry schema): the remote server owns argument validation, and
  # its advertised schema is surfaced for listing via input_schema_to_json.
  class Base < ApplicationTool
    service_kind :mcp
    abstract_tool true

    class_attribute :remote_tool_name, default: nil
    class_attribute :remote_input_schema, default: {}

    def call(**args)
      service.client.call(self.class.remote_tool_name, args)
    end

    # Surface the remote tool's advertised argument schema verbatim so MCP
    # clients know what arguments to send. Validation stays permissive (the
    # remote server owns it); only the *listing* uses this.
    def self.input_schema_to_json
      remote = remote_input_schema
      return JSON.parse(remote) if remote.is_a?(String)

      remote.with_indifferent_access.slice :type, :properties, :required
    end
  end
end
