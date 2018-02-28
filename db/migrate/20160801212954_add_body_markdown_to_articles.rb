class AddBodyMarkdownToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :body_markdown, :text
  end
end
