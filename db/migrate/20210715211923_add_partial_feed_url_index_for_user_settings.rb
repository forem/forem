class AddPartialFeedUrlIndexForUserSettings < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    # adds an index only on users with a feed URL, as they are a tiny percentage of the total
    # number of users, there is no need to add a full index as most entries will be empty
    add_index :users_settings, :feed_url, where: "COALESCE(feed_url, '') <> ''", algorithm: :concurrently
  end
end
