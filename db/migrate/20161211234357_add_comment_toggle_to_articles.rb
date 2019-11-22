class AddCommentToggleToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :show_comments, :boolean, default: false
  end
end
