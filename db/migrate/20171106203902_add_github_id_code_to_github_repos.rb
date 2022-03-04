class AddGithubIdCodeToGithubRepos < ActiveRecord::Migration[5.1]
  def change
    add_column :github_repos, :github_id_code, :integer
  end
end
