class AddTsvectorColumnToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :tsv, :tsvector
  end
end
