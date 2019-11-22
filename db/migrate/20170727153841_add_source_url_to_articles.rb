class AddSourceUrlToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :feed_source_url, :string
  end
end
