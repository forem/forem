class AddFeedUrlToUsers < ActiveRecord::Migration
  def change
    add_column :users, :feed_url, :string
    add_column :articles, :published_from_feed, :boolean, default: false
  end
end
