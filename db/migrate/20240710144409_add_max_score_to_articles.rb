class AddMaxScoreToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :max_score, :integer, default: 0
  end
end
