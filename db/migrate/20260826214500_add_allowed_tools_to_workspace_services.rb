class AddAllowedToolsToWorkspaceServices < ActiveRecord::Migration[8.1]
  def change
    add_column :workspace_services, :allowed_tools, :text
  end
end
