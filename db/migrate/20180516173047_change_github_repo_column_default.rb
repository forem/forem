class ChangeGithubRepoColumnDefault < ActiveRecord::Migration[5.1]
  def change
    change_column_default(:github_repos, :info_hash, {}.to_yaml)
  end
end
