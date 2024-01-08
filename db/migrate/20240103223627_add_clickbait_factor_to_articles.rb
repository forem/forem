class AddClickbaitFactorToArticles < ActiveRecord::Migration[7.0]
  def change
    # Clickbait score is a number between 0 and 1 that represents how clickbaity the article is — higher is more clickbaity
    add_column :articles, :clickbait_score, :float, default: 0.0
  end
end
