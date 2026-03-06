class AddFeedHealthToUsersSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :users_settings, :feed_status, :integer, default: 0, null: false
    add_column :users_settings, :feed_status_message, :string
    add_column :users_settings, :consecutive_feed_failures, :integer, default: 0, null: false
  end
end
