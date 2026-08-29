# frozen_string_literal: true

module WorkplaceAdminTools
  # Disconnects (unlinks) a service from a managed workspace.
  class DisconnectServiceTool < Base
    description "Remove a service from a managed workspace"

    arguments do
      required(:workspace_id).filled(:integer).description("The ID of the workspace to remove the service from")
      required(:service_id).filled(:integer).description("The ID of the service to disconnect")
    end

    def call(workspace_id:, service_id:)
      ws = resolve_managed!(workspace_id)
      join = ws.workspace_services.find_by(service_id: service_id)
      raise ArgumentError, "Service #{service_id} is not connected to workspace #{ws.id}" if join.nil?

      join.destroy!
      { workspace_id: ws.id, service_id: service_id, connected: false }
    end
  end
end
