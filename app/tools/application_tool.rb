# frozen_string_literal: true

class ApplicationTool < ActionTool::Base
  class_attribute :config_service_kind, default: nil
  class_attribute :config_tool_kind, default: nil

  class << self
    # Declares which service kind this tool runs against (e.g. :github).
    def service_kind(value = nil)
      self.config_service_kind = value.to_s if value
      config_service_kind
    end

    # Declares the machine name of this tool, used to build the MCP tool name.
    def kind(value = nil)
      self.config_tool_kind = value.to_s if value
      config_tool_kind || name.demodulize.chomp("Tool").underscore
    end

    # Marks a base handler as abstract so it is not exposed directly.
    def abstract_tool(value = true)
      @abstract_tool = value
    end

    def abstract_tool?
      @abstract_tool || false
    end

    # Concrete handlers that run against the given service kind.
    def handlers_for(service_kind)
      descendants
        .reject(&:abstract_tool?)
        .reject { |handler| handler.name.blank? }
        .select { |handler| handler.service_kind == service_kind.to_s }
    end

    # Builds one MCP tool class per handler, bound to the given service instance.
    # Each bound class gets a unique MCP tool name and carries its service_id.
    def expose_for(service)
      handlers_for(service.kind).map do |handler|
        build_bound_handler(handler, service)
      end
    end

    private

    # Copy the DSL state (schema, description, annotations, ...) that does not
    # survive Class.new, since those live in class-level ivars.
    def copy_dsl_state(source, target)
      %i[
        @description @annotations @input_schema @collected_metadata
        @authorization_blocks @tags @metadata
      ].each do |ivar|
        target.instance_variable_set(ivar, source.instance_variable_get(ivar)) if source.instance_variable_defined?(ivar)
      end
    end

    def build_bound_handler(handler, service)
      klass = Class.new(handler)
      copy_dsl_state(handler, klass)
      klass.tool_name("#{handler.kind}_#{service.class.name.demodulize.chomp("Service").underscore}_#{service.name.parameterize}")
      klass.class_attribute :service_id, default: service.id
      klass
    end
  end
end
