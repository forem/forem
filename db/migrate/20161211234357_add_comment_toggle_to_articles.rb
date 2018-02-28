class AddCommentToggleToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :show_comments, :boolean, default: false
  end
end
