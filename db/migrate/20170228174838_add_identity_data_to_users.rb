class AddIdentityDataToUsers < ActiveRecord::Migration
  def change
    add_column :identities, :auth_data_dump, :text
    add_column :users, :github_created_at, :datetime
    add_column :users, :twitter_created_at, :datetime
    add_column :users, :twitter_following_count, :integer
    add_column :users, :twitter_followers_count, :integer
  end
end
