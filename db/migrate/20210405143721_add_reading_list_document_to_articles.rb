class AddReadingListDocumentToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :reading_list_document, :tsvector
  end
end

