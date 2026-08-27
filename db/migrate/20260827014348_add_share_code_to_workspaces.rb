class AddShareCodeToWorkspaces < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :share_code, :string
  end
end
