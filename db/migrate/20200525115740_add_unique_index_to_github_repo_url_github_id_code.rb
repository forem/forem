class AddUniqueIndexToGithubRepoUrlGithubIdCode < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :github_repos, :url, unique: true, algorithm: :concurrently
    add_index :github_repos, :github_id_code, unique: true, algorithm: :concurrently
  end
end
