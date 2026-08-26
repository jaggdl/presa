class AddShareCodeDigestToWorkspaces < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :share_code_digest, :string
  end
end
