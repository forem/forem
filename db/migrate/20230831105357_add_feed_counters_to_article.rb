class AddFeedCountersToArticle < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :articles, :feed_impressions_count, :integer, default: 0
      add_column :articles, :feed_clicks_count, :integer, default: 0
    end
  end
end
