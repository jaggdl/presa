# frozen_string_literal: true

class CreateOpenapiKinds < ActiveRecord::Migration[8.1]
  def change
    create_table :openapi_kinds do |t|
      t.references :team, null: false, foreign_key: true
      t.string :title, null: false
      t.string :namespace, null: false
      t.text :description
      t.string :base_url
      t.string :spec_url
      t.json :definition
      t.string :health_op
      t.string :health_identity
      t.json :extra_credentials, default: []

      t.timestamps

      t.index [ :team_id, :namespace ], unique: true
    end

    add_reference :services, :openapi_kind, foreign_key: true, null: true
  end
end
