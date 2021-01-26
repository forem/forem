class AddIndexToUsersFeedFetchedAt < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :users, :feed_fetched_at, algorithm: :concurrently
  end
end
