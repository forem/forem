class AddFeedSuccessScoreToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :feed_success_score, :float, default: 0.0, null: false
  end
end
