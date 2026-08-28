class AddRoleToTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :team_memberships, :role, :integer, default: 0, null: false
  end
end
