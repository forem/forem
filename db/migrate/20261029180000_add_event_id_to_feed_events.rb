class AddEventIdToFeedEvents < ActiveRecord::Migration[7.0]
  def up
    add_column :feed_events, :event_id, :uuid
    create_table :feed_event_receipts, id: :uuid do |t|
      t.datetime :created_at, null: false
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Delivery receipts and event IDs must be retained for replay protection"
  end
end
