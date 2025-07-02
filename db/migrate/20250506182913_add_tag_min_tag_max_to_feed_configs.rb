class AddTagMinTagMaxToFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :feed_configs, :recent_tag_count_min, :integer, default: 0
    add_column :feed_configs, :recent_tag_count_max, :integer, default: 0
    add_column :feed_configs, :all_time_tag_count_min, :integer, default: 0
    add_column :feed_configs, :all_time_tag_count_max, :integer, default: 0
  end
end
