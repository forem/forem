class AddIndexToGithubReposOnUserIdAndFeatured < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :github_repos, [:user_id, :featured], algorithm: :concurrently
  end
end
