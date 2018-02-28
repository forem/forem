class AddHotnessScoreToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :hotness_score, :integer, null: false, default: 0
  end
end
