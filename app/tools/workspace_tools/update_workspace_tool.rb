# frozen_string_literal: true

module WorkspaceTools
  # Updates a managed workspace's name and/or description.
  class UpdateWorkspaceTool < Base
    description "Update a managed workspace's name and/or description"

    arguments do
      required(:workspace_id).filled(:integer).description("The ID of the workspace to update")
      optional(:name).filled(:string).description("The new workspace name")
      optional(:description).filled(:string).description("The new workspace description")
    end

    def call(workspace_id:, name: nil, description: nil)
      raise ArgumentError, "Provide a name or description to update" if name.blank? && description.nil?

      ws = resolve_managed!(workspace_id)
      ws.name = name if name.present?
      ws.description = description if !description.nil?
      ws.save!
      { id: ws.id, name: ws.name, description: ws.description }
    end
  end
end
