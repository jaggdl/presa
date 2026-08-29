# frozen_string_literal: true

module WorkplaceAdminTools
  # Connects (links) a service owned by the same team to a managed workspace.
  class ConnectServiceTool < Base
    description "Link a service to a managed workspace so its tools become available in that workspace"

    arguments do
      required(:workspace_id).filled(:integer).description("The ID of the workspace to add the service to")
      required(:service_id).filled(:integer).description("The ID of the service to connect")
    end

    def call(workspace_id:, service_id:)
      ws = resolve_managed!(workspace_id)
      svc = service.team.services.find_by(id: service_id)
      raise ArgumentError, "Service #{service_id} not found" if svc.nil?

      join = ws.workspace_services.find_or_initialize_by(service: svc)
      join.save!
      { workspace_id: ws.id, service_id: svc.id, connected: true }
    end
  end
end
