class AddDefaultFeedToUsersSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :users_settings, :config_homepage_feed, :integer, default: 0, null: false
  end
end
