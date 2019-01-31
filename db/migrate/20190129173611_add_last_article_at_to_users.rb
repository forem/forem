class AddLastArticleAtToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :last_article_at, :datetime, default: "2017-01-01 05:00:00"
    add_column :users, :last_comment_at, :datetime, default: "2017-01-01 05:00:00"
    add_column :organizations, :last_article_at, :datetime, default: "2017-01-01 05:00:00"
  end
end
