class AddCommentScoreIndexToArticles < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :articles, :comment_score, algorithm: :concurrently
  end
end
