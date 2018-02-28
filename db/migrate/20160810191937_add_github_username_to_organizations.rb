class AddGithubUsernameToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :github_username, :string
  end
end
