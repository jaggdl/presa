class AddNameToOauthClientCredentials < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_client_credentials, :name, :string

    # Backfill existing rows with a readable label so `name` can be NOT NULL.
    reversible do |dir|
      dir.up do
        OauthClientCredential.reset_column_information
        OauthClientCredential.where(name: nil).find_each do |cred|
          cred.update_column(:name, cred.client_id.to_s[0, 30].presence || cred.provider)
        end
        change_column_null :oauth_client_credentials, :name, false
      end

      dir.down do
        change_column_null :oauth_client_credentials, :name, true
      end
    end
  end
end
