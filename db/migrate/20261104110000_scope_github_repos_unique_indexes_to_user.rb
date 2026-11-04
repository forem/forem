class ScopeGithubReposUniqueIndexesToUser < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :github_repos, %i[user_id github_id_code], unique: true, algorithm: :concurrently
    add_index :github_repos, %i[user_id url], unique: true, algorithm: :concurrently

    remove_index :github_repos, :github_id_code, unique: true, algorithm: :concurrently
    remove_index :github_repos, :url, unique: true, algorithm: :concurrently
  end

  # Once several users have pinned the same repository, the global unique indexes can't be restored
  # without deleting some of their pins, so this migration is deliberately not reversible.
  # To roll back the application code, leave the indexes in place: they are compatible with the
  # previous (global) validations, since every globally unique pair is also unique per user.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
