class AddDisplayedCommentsCountToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :displayed_comments_count, :integer
  end
end
