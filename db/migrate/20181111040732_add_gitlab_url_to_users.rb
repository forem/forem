class AddGitlabUrlToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :gitlab_url, :string
  end
end
