class AddBodyMarkdownToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :body_markdown, :text
    add_column :events, :processed_html, :text
  end
end
