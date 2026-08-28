class AddExpiresAtToSessions < ActiveRecord::Migration[8.1]
  def up
    add_column :sessions, :expires_at, :datetime

    execute <<~SQL.squish
      UPDATE sessions
      SET expires_at = strftime('%Y-%m-%d %H:%M:%f', 'now', '+1 day')
      WHERE expires_at IS NULL
    SQL

    change_column :sessions, :expires_at, :datetime
  end

  def down
    remove_column :sessions, :expires_at
  end
end
