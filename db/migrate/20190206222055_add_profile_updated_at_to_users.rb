class AddProfileUpdatedAtToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :profile_updated_at, :datetime, default: "2017-01-01 05:00:00"
    add_column :organizations, :profile_updated_at, :datetime, default: "2017-01-01 05:00:00"
    add_column :users, :github_repos_updated_at, :datetime, default: "2017-01-01 05:00:00"
  end
end
