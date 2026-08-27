class CreateOauthClientCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_client_credentials do |t|
      t.string :provider, null: false
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.string :scopes
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index [ :provider, :client_id ], unique: true
    end
  end
end
