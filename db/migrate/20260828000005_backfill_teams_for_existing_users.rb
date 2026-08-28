class BackfillTeamsForExistingUsers < ActiveRecord::Migration[8.1]
  def up
    User.left_outer_joins(:teams).where(teams: { id: nil }).find_each do |user|
      user.teams.create!(name: "#{user.email_address}'s team")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "teams created for existing users cannot be safely reverted"
  end
end
