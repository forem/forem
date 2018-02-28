class AddSourceUrlToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :feed_source_url, :string
  end
end
