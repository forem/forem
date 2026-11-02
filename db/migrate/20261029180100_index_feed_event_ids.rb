class IndexFeedEventIds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :feed_events, :event_id, unique: true, where: "event_id IS NOT NULL", algorithm: :concurrently
  end
end
