class AddProcessedHtmlToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :processed_html, :text
  end
end
