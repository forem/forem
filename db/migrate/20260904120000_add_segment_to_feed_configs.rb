class AddSegmentToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :segment, :integer, default: 0, null: false
  end
end
