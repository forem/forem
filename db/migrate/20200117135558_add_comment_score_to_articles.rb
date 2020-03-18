class AddCommentScoreToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :comment_score, :integer, default: 0
  end
end
