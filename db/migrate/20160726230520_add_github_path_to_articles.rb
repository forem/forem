class AddGithubPathToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :github_path, :string
  end
end
