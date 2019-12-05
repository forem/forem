class AddBodyMarkdownToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :body_markdown, :text
  end
end
