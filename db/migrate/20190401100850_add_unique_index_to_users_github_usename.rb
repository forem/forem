class AddUniqueIndexToUsersGithubUsename < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :github_username, unique: true
  end
end
