class AddAnyCommentsHiddenToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :any_comments_hidden, :boolean, default: false
    add_column :podcast_episodes, :any_comments_hidden, :boolean, default: false
  end
end
