class TransferOwnershipToTeams < ActiveRecord::Migration[8.1]
  # Moves ownership of services, workspaces, and OAuth client credentials from
  # the individual user to the user's team. Each user maps to exactly one team
  # today (created at signup / backfilled), so records are re-pointed at that
  # user's team membership. The old user ownership columns are dropped.
  def up
    transfer_services
    transfer_workspaces
    transfer_oauth_client_credentials
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "team ownership cannot be automatically reverted to user ownership"
  end

  private

  def transfer_services
    add_reference :services, :team, foreign_key: true
    backfill(:services, :user_id)
    change_column_null :services, :team_id, false
    remove_index :services, name: "index_services_on_user_id_and_type_and_name"
    remove_foreign_key :services, :users
    remove_index :services, :user_id
    remove_column :services, :user_id
    add_index :services, [ :team_id, :type, :name ], unique: true
  end

  def transfer_workspaces
    add_reference :workspaces, :team, foreign_key: true
    backfill(:workspaces, :user_id)
    change_column_null :workspaces, :team_id, false
    remove_foreign_key :workspaces, :users
    remove_index :workspaces, :user_id
    remove_column :workspaces, :user_id
  end

  def transfer_oauth_client_credentials
    add_reference :oauth_client_credentials, :team, foreign_key: true
    backfill(:oauth_client_credentials, :created_by_user_id)
    change_column_null :oauth_client_credentials, :team_id, false
    remove_foreign_key :oauth_client_credentials, :users
    remove_index :oauth_client_credentials, :created_by_user_id
    remove_column :oauth_client_credentials, :created_by_user_id
  end

  def backfill(table, owner_column)
    execute <<~SQL
      UPDATE #{table}
      SET team_id = (
        SELECT team_memberships.team_id
        FROM team_memberships
        WHERE team_memberships.user_id = #{table}.#{owner_column}
        LIMIT 1
      )
    SQL
  end
end
