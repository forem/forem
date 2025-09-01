class CreateFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :feed_configs do |t|
      t.float   :tag_follow_weight, default: 1.0
      t.float   :user_follow_weight, default: 1.0
      t.float   :organization_follow_weight, default: 1.0
      t.float   :feed_success_weight, default: 1.0
      t.float   :recency_weight, default: 1.0
      t.float   :comment_score_weight, default: 1.0
      t.float   :score_weight, default: 1.0
      t.float   :precomputed_selections_weight, default: 1.0
      t.float   :comment_recency_weight, default: 1.0
      t.float   :label_match_weight, default: 1.0
      t.float   :lookback_window_weight, default: 1.0

      t.float   :feed_success_score, default: 0.0
      t.bigint  :feed_impressions_count, default: 0
      t.timestamps
      t.index :feed_success_score
    end
  end
end
