class AddLockoutToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :failed_login_attempts, :integer, default: 0, null: false
    add_column :users, :locked_until, :datetime
  end
end
