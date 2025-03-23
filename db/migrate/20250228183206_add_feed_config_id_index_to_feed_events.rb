class AddFeedConfigIdIndexToFeedEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :feed_events, :feed_config_id, algorithm: :concurrently
  end
end
