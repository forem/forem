class AddCanonicalUrlToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :canonical_url, :string
  end
end
