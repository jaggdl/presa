class AddDescriptionToWorkspaces < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :description, :text
  end
end
