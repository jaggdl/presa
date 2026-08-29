# frozen_string_literal: true

module WorkplaceAdminTools
  # Abstract base for workspace-management tools. Not exposed directly.
  # Resolves the bound Workplace Admin service and provides helpers to look up
  # a workspace within the service's managed set. All tools are scoped to the
  # owning team's workspaces, so a Workplace Admin service can never mutate
  # another team's data.
  class Base < ApplicationTool
    service_kind :workplace_admin
    abstract_tool true

    private

    # The bound Workplace Admin service instance.
    def workspace_service
      service
    end

    # Looks up a workspace by id among the service's managed workspaces, raising
    # a clear error when the id is missing or out of scope.
    def resolve_managed!(id)
      found = workspace_service.find_managed_workspace(id)
      raise ArgumentError, "Workspace #{id} is not managed by this service" if found.nil?

      found
    end
  end
end
