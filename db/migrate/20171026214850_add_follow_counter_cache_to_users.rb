class AddFollowCounterCacheToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :following_tags_count, :integer, null: false, default: 0
    add_column :users, :following_users_count, :integer, null: false, default: 0
    add_column :users, :following_orgs_count, :integer, null: false, default: 0
  end
end
