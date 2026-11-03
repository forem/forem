class AddActiveBucketAndSuccessScoreIndexToFeedConfigs < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :feed_configs,
              %i[targeting_bucket feed_success_score],
              order: { targeting_bucket: :desc, feed_success_score: :desc },
              where: "(archived = false)",
              name: "index_feed_configs_on_active_bucket_and_success_score",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
