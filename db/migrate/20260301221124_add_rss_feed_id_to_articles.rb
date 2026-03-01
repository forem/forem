class AddRssFeedIdToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :articles, :rss_feed, null: true, index: { algorithm: :concurrently }
  end
end
