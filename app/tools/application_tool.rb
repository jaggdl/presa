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
    # Defaults to the tool's class name with the "Tool" suffix stripped and
    # snake_cased (e.g. SearchUserMediaTool -> search_user_media). Bound
    # handlers are anonymous Class.new subclasses, so fall back to the
    # superclass name (the concrete handler) when the class itself is unnamed.
    def kind(value = nil)
      self.config_tool_kind = value.to_s if value
      config_tool_kind || tool_name_from_class
    end

    # The stable identifier used to select this tool in a workspace's
    # `allowed_tools` list: a proxied remote MCP tool's remote name, otherwise
    # the tool's kind (e.g. "search_user_media").
    def tool_key
      if respond_to?(:remote_tool_name) && remote_tool_name.present?
        remote_tool_name.to_s
      else
        kind.to_s
      end
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
    #
    # For a remote-MCP service (Services::Mcp) there are no static handlers:
    # one dynamic class is built per tool the remote endpoint advertises.
    def expose_for(service)
      return expose_remote_mcp(service) if service.is_a?(Services::Mcp)

      handlers_for(service.kind).map do |handler|
        build_bound_handler(handler, service)
      end
    end

    private

    def tool_name_from_class
      source = name.blank? ? superclass&.name : name
      source.to_s.demodulize.chomp("Tool").underscore
    end

    # Remote MCP services proxy another server's tools. Build one dynamic class
    # per advertised tool, named "<service slug>_<remote tool name>" (e.g.
    # "search_web_search"), reusing the remote's name/description.
    def expose_remote_mcp(service)
      service.remote_tools.filter_map do |remote_tool|
        name = remote_tool[:name] || remote_tool["name"]
        next if name.blank?

        klass = Class.new(Mcp::Base)
        klass.tool_name(remote_tool_name(service, name))
        klass.description(remote_tool[:description] || remote_tool["description"] || "")
        klass.remote_tool_name = name
        klass.remote_input_schema = remote_tool[:inputSchema] || remote_tool["inputSchema"] || {}
        klass.class_attribute :service_id, default: service.id
        klass
      end
    end

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
      klass.tool_name(bound_tool_name(handler, service))
      klass.class_attribute :service_id, default: service.id
      klass
    end

    # The MCP tool name for a static handler: "<service kind>_<kind>", e.g.
    # "github_list_issues". Service kind first groups every tool a service
    # exposes under one prefix. The service name is only appended when it is
    # needed to disambiguate — i.e. the workspace has more than one service of
    # the same kind — keeping names short and token-efficient.
    def bound_tool_name(handler, service)
      base = "#{service_kind_slug(service)}_#{handler.kind}"
      service_name_needed?(service) ? "#{base}_#{service.name.parameterize}" : base
    end

    # The MCP tool name for a remote-MCP service: just the remote tool's name
    # (e.g. "web_search"). The service slug is appended only when the workspace
    # has more than one MCP service, to keep remote tool names from colliding.
    def remote_tool_name(service, remote_name)
      service_name_needed?(service) ? "#{service.name.underscore}_#{remote_name}" : remote_name
    end

    def service_kind_slug(service)
      service.class.name.demodulize.chomp("Service").underscore
    end

    def service_name_needed?(service)
      return false unless Current.workspace

      Current.workspace.services.count { |s| s.kind == service.kind } > 1
    end
  end

  # Wrap the framework's actual execution in our invocation logging. We hook
  # here (rather than the subclass `call`) so success/error/status and timing
  # are captured for every tool, bound to the current API token's workspace.
  def call_with_schema_validation!(**args)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    authorize_call!
    result, meta = super
    record_invocation(args: args, result: result, status: "success", duration_ms: elapsed_ms(started_at))
    [ result, meta ]
  rescue StandardError => e
    record_invocation(args: args, result: nil, status: "error", error_message: e.message, duration_ms: elapsed_ms(started_at))
    raise
  end

  # A tool may only run if it is allowed for its service within the current
  # workspace. Generic tools carry no service and are always allowed. This is
  # a call-time guard in addition to `filter_tools`, which controls only the
  # advertised tool list.
  def authorize_call!
    return if Current.workspace.nil? || !self.class.respond_to?(:service_id) || service.nil?

    join = Current.workspace.workspace_services.find_by(service_id: service.id)
    return if join&.tool_allowed?(self.class.tool_key)

    raise NotAllowedToolError, "Tool #{self.class.tool_name} is not allowed in this workspace"
  end

  # Raised when a tool is invoked that its workspace does not allow.
  class NotAllowedToolError < StandardError; end

  private

  def record_invocation(args:, result:, status:, error_message: nil, duration_ms: nil)
    ToolInvocation.record!(
      api_token: Current.api_token,
      service: service,
      tool_name: self.class.tool_name,
      arguments: args,
      status: status,
      error_message: error_message,
      duration_ms: duration_ms,
      response: result
    )
  rescue StandardError => e
    Rails.logger.error("Tool invocation logging failed: #{e.message}")
  end

  # The bound service; generic (service-less) tools return nil.
  def service
    @service ||= Service.find_by(id: self.class.service_id)
  end

  # Friendly input parameters [{name, type, required, description}] derived
  # from the tool's declared input schema.
  def self.input_parameters
    schema = (input_schema_to_json || {}).with_indifferent_access
    properties = (schema[:properties] || {}).with_indifferent_access
    required = Array(schema[:required]).map(&:to_s)

    properties.map do |name, meta|
      meta = meta.with_indifferent_access
      type = meta[:type] || (meta[:anyOf].is_a?(Array) && meta[:anyOf].map { |o| o[:type] }.compact.uniq.join(" | "))
      type = "array[#{Array(meta.dig(:items, :type)).first}]" if meta[:items].is_a?(Hash) && meta[:items][:type]
      {
        name: name,
        type: type || "any",
        required: required.include?(name.to_s),
        description: meta[:description]
      }
    end
  end

  def elapsed_ms(started_at)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).round
  end
end
