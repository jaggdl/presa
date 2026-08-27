class CreateOauthGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_grants do |t|
      t.references :service, null: false, foreign_key: true, index: { unique: true }
      t.references :oauth_client_credential, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :access_token, null: false
      t.string :refresh_token
      t.string :token_type
      t.string :scope
      t.datetime :expires_at
      t.string :remote_user_key
      t.timestamps
    end
  end
end
