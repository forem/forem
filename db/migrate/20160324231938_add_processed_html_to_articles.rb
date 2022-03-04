class AddProcessedHtmlToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :processed_html, :text
  end
end
