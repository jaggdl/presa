class MoveApiTokensToWorkspaces < ActiveRecord::Migration[8.1]
  def up
    remove_reference :api_tokens, :user, foreign_key: true
    execute "DELETE FROM api_tokens"
    add_reference :api_tokens, :workspace, null: false, foreign_key: true
  end

  def down
    remove_reference :api_tokens, :workspace, foreign_key: true
    add_reference :api_tokens, :user, null: false, foreign_key: true
  end
end
