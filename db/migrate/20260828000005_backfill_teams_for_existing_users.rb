class BackfillTeamsForExistingUsers < ActiveRecord::Migration[8.1]
  # Creates a default team for every user without one and a membership linking
  # them. Implemented as raw SQL (no app models) so it stays independent of
  # model code that may change after this migration ships.
  def up
    execute <<~SQL
      INSERT INTO teams (name, created_at, updated_at)
      SELECT email_address || '''s team', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      WHERE id NOT IN (SELECT user_id FROM team_memberships)
    SQL

    execute <<~SQL
      INSERT INTO team_memberships (team_id, user_id, created_at, updated_at)
      SELECT t.id, u.id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users u
      JOIN teams t ON t.name = u.email_address || '''s team'
      WHERE u.id NOT IN (SELECT user_id FROM team_memberships)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "teams created for existing users cannot be safely reverted"
  end
end
