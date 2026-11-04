class AddGithubOrganizationsToUsersSettings < ActiveRecord::Migration[8.0]
  def up
    add_column :users_settings, :github_organizations, :string, array: true, default: [], null: false
  end

  def down
    # The application no longer reads the column once this migration is rolled back.
    safety_assured { remove_column :users_settings, :github_organizations }
  end
end
