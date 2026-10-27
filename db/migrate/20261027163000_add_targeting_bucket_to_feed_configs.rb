class AddTargetingBucketToFeedConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :feed_configs, :targeting_bucket, :string, default: "all", null: false
  end
end
