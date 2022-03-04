class AddLastCommentAtToArticles < ActiveRecord::Migration[5.1]
  def change
    add_column :articles, :last_comment_at, :datetime, default: "2017-01-01 05:00:00"
  end
end
