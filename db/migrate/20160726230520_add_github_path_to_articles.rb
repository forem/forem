class AddGithubPathToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :github_path, :string
  end
end
