class AddFeedFetchedAtToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :feed_fetched_at, :datetime, default: "2017-01-01 05:00:00"
  end
end
