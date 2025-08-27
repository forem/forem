class AddRecentArticleSupressionRateToFeedConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :feed_configs, :recent_article_suppression_rate, :float, default: 0.0, null: false
    add_column :feed_configs, :published_today_weight, :float, default: 0.0, null: false
    add_column :feed_configs, :language_match_weight, :float, default: 1.0, null: false
  end
end
