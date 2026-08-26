class CreateBotAuthorizations < ActiveRecord::Migration[8.1]
  def change
    create_table :bot_authorizations do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :request_token, null: false
      t.string :name, null: false
      t.text :justification
      t.integer :status, default: 0, null: false
      t.string :code_digest
      t.datetime :code_expires_at
      t.datetime :approved_at
      t.datetime :issued_at
      t.datetime :expires_at, null: false
      t.timestamps

      t.index :request_token, unique: true
      t.index [ :workspace_id, :name ]
    end
  end
end
