class AddFeedUrlToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :feed_url, :string
    add_column :articles, :published_from_feed, :boolean, default: false
  end
end
