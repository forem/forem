class AddCompellingScoreToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :compellingness_score, :float, default: 0.0, null: false
  end
end
