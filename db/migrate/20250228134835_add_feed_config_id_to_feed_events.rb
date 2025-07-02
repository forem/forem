class AddFeedConfigIdToFeedEvents < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :feed_events, :feed_config_id, :bigint
  end
end
