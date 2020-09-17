class AddHotnessScoreToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :hotness_score, :integer, null: false, default: 0
  end
end
