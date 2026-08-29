# frozen_string_literal: true

module WorkplaceAdminTools
  # Reads a managed workspace's recent tool-invocation history.
  class ReadWorkspaceInvocationsTool < Base
    description "Read a managed workspace's recent tool invocations"

    arguments do
      required(:workspace_id).filled(:integer).description("The ID of the workspace")
      optional(:limit).filled(:integer, gt?: 0, lteq?: 100).description("Max invocations to return (default 50)")
    end

    def call(workspace_id:, limit: 50)
      ws = resolve_managed!(workspace_id)
      invocations = ws.tool_invocations.includes(:service).order(created_at: :desc).limit(limit)
      {
        workspace_id: ws.id,
        invocations: invocations.map do |i|
          {
            id: i.id,
            tool_name: i.tool_name,
            service: i.service&.name,
            status: i.status,
            created_at: i.created_at,
            duration_ms: i.duration_ms
          }
        end
      }
    end
  end
end
