class AddCanonicalUrlToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :canonical_url, :string
  end
end
