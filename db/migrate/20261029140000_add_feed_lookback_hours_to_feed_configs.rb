class AddFeedLookbackHoursToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :feed_lookback_hours, :integer, default: 0, null: false
  end
end
