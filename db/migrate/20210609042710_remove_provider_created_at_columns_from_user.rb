class RemoveProviderCreatedAtColumnsFromUser < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :users, :apple_created_at
      remove_column :users, :facebook_created_at
      remove_column :users, :github_created_at
      remove_column :users, :twitter_created_at
    end
  end
end
