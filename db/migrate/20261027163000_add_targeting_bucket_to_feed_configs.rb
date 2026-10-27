class AddTargetingBucketToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :targeting_bucket, :integer, default: 0, null: false
  end
end
