class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.references :user, null: false, foreign_key: true
      t.string :type, null: false
      t.string :name, null: false
      t.json :config

      t.timestamps
    end

    add_index :services, %i[user_id type name], unique: true
  end
end
