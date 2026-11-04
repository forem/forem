class ScopeGithubReposUniqueIndexesToUser < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :github_repos, %i[user_id github_id_code], unique: true, algorithm: :concurrently
    add_index :github_repos, %i[user_id url], unique: true, algorithm: :concurrently

    remove_index :github_repos, :github_id_code, unique: true, algorithm: :concurrently
    remove_index :github_repos, :url, unique: true, algorithm: :concurrently
  end

  # NOTE: restoring the global indexes fails if several users pinned the same repository in the meantime.
  def down
    add_index :github_repos, :github_id_code, unique: true, algorithm: :concurrently
    add_index :github_repos, :url, unique: true, algorithm: :concurrently

    remove_index :github_repos, %i[user_id github_id_code], unique: true, algorithm: :concurrently
    remove_index :github_repos, %i[user_id url], unique: true, algorithm: :concurrently
  end
end
