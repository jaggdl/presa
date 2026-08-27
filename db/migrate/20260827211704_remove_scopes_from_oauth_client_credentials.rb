class RemoveScopesFromOauthClientCredentials < ActiveRecord::Migration[8.1]
  def change
    remove_column :oauth_client_credentials, :scopes, :string
  end
end
