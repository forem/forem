class AddAllowsArticleEditsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :allows_article_edits, :boolean, default: false
  end
end
