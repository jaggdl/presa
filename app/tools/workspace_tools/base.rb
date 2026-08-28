# frozen_string_literal: true

module WorkspaceTools
  # Abstract base for workspace-management tools. Not exposed directly.
  # Resolves the bound Workspace service and provides helpers to look up a
  # workspace within the service's managed set. All tools are scoped to the
  # service owner's own workspaces, so a Workspace service can never mutate
  # another user's data.
  class Base < ApplicationTool
    service_kind :workspace
    abstract_tool true

    private

    # The bound Workspace service instance.
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
