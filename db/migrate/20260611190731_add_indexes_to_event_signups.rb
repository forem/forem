class AddIndexesToEventSignups < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :event_signups, :user_id, algorithm: :concurrently
    add_index :event_signups, :event_id, algorithm: :concurrently
    add_index :event_signups, [:user_id, :event_id], unique: true, algorithm: :concurrently
    add_index :event_signups, :notified_1_day_before, algorithm: :concurrently
    add_index :event_signups, :notified_1_hour_before, algorithm: :concurrently
  end
end
