class AddPreviewToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :preview_link, :text
    add_column :articles, :processed_preview_link, :text
  end
end
