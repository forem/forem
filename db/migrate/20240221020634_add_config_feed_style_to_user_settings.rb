class AddConfigFeedStyleToUserSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :users_settings, :config_feed_style, :integer, default: 0, null: false
  end
end
