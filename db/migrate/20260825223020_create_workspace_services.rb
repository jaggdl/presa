class CreateWorkspaceServices < ActiveRecord::Migration[8.1]
  def change
    create_table :workspace_services do |t|
      t.references :workspace, null: false, foreign_key: true, index: false
      t.references :service, null: false, foreign_key: true, index: false

      t.timestamps
    end

    add_index :workspace_services, %i[workspace_id service_id], unique: true
    add_index :workspace_services, :service_id
  end
end
