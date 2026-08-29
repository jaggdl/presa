class AddLogToolDataToWorkspaces < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :log_tool_data, :boolean, default: false, null: false
  end
end
