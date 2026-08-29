# frozen_string_literal: true

module WorkplaceAdminTools
  # Sets a workspace's allowed tools for a connected service. Pass `all: true`
  # to allow every tool the service exposes, or a list of tool keys (the stable
  # identifiers used to select tools) to restrict to a subset.
  class SetWorkspaceAllowedToolsTool < Base
    description "Set which tools of a connected service are allowed in a managed workspace"

    arguments do
      required(:workspace_id).filled(:integer).description("The ID of the workspace")
      required(:service_id).filled(:integer).description("The ID of the connected service")
      optional(:all).filled(:bool).description("When true, allow every tool the service exposes")
      optional(:allowed_tools).array(:string).description("Tool keys to allow; the exact list when `all` is false (use read_workspace_allowed_tools to see the keys)")
    end

    def call(workspace_id:, service_id:, all: nil, allowed_tools: nil)
      ws = resolve_managed!(workspace_id)
      join = ws.workspace_services.find_by(service_id: service_id)
      raise ArgumentError, "Service #{service_id} is not connected to workspace #{ws.id}" if join.nil?

      join.allowed_tools = if all
                             [ WorkspaceService::ALLOW_ALL ]
      else
                             keys = Array(allowed_tools).map(&:to_s).reject(&:blank?)
                             keys.empty? ? [] : keys
      end
      join.save!
      { workspace_id: ws.id, service_id: service_id, allowed_tools: join.allowed_tools, all_allowed: join.all_tools_allowed? }
    end
  end
end
