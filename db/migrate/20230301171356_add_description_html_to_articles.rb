class AddDescriptionHtmlToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :description_html, :text
  end
end
