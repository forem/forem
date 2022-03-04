class AddScoreToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :score, :integer, default: 0
  end
end
