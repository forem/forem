class AddGithubUsernameToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_column :organizations, :github_username, :string
  end
end
