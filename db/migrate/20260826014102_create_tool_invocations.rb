class CreateToolInvocations < ActiveRecord::Migration[8.1]
  def change
    create_table :tool_invocations do |t|
      t.references :api_token, null: false, foreign_key: true
      t.references :service, foreign_key: true
      t.string :tool_name, null: false
      t.json :arguments, default: {}
      t.json :response
      t.string :status, default: "success", null: false
      t.text :error_message
      t.integer :duration_ms

      t.timestamps
    end

    add_index :tool_invocations, %i[api_token_id created_at]
  end
end
