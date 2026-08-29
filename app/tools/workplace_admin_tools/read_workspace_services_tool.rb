# frozen_string_literal: true

module WorkplaceAdminTools
  # Reads a managed workspace's currently connected services and the services
  # the team could still add to it (those of the same team not yet connected).
  class ReadWorkspaceServicesTool < Base
    description "Read a managed workspace's connected services and the services that could be added"

    arguments do
      required(:workspace_id).filled(:integer).description("The ID of the workspace")
    end

    def call(workspace_id:)
      ws = resolve_managed!(workspace_id)
      connected_ids = ws.workspace_services.pluck(:service_id)
      connected = service.team.services.where(id: connected_ids).order(:name)
      available = service.team.services.where.not(id: connected_ids).order(:name)

      {
        workspace_id: ws.id,
        workspace_name: ws.name,
        connected_services: connected.map { |s| { id: s.id, name: s.name, kind: s.kind } },
        addable_services: available.map { |s| { id: s.id, name: s.name, kind: s.kind } }
      }
    end
  end
end
