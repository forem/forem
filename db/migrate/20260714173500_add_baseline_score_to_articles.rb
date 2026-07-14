class AddBaselineScoreToArticles < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :baseline_score, :integer, default: 0, null: false
  end
end
