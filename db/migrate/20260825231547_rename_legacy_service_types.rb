class RenameLegacyServiceTypes < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE services SET type = 'Services::Github' WHERE type = 'GithubService'"
  end

  def down
    execute "UPDATE services SET type = 'GithubService' WHERE type = 'Services::Github'"
  end
end
