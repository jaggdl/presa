# frozen_string_literal: true

module WorkspaceTools
  # Reads a workspace's connected services and, for each, the tools it currently
  # allows (their MCP tool names) plus every tool the service exposes.
  class ReadWorkspaceAllowedToolsTool < Base
    description "Read a managed workspace's connected services and their currently allowed tools"

    arguments do
      required(:workspace_id).filled(:integer).description("The ID of the workspace to inspect")
    end

    def call(workspace_id:)
      ws = resolve_managed!(workspace_id)
      joins = ws.workspace_services.includes(:service).order("services.name")
      {
        workspace_id: ws.id,
        services: joins.map do |join|
          tools = ApplicationTool.expose_for(join.service)
          {
            service_id: join.service.id,
            service_name: join.service.name,
            kind: join.service.kind,
            all_allowed: join.all_tools_allowed?,
            allowed_tools: join.all_tools_allowed? ? tools.map(&:tool_key) : tools.select { |t| join.tool_allowed?(t.tool_key) }.map(&:tool_key)
          }
        end
      }
    end
  end
end
