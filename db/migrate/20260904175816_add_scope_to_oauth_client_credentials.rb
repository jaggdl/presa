class AddScopeToOauthClientCredentials < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_client_credentials, :scope, :string
  end
end
