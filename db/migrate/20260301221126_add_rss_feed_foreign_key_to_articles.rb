class AddRssFeedForeignKeyToArticles < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :articles, :rss_feeds, on_delete: :nullify, validate: false
  end
end
