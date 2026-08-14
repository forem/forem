class AddIndexesToEventSignups < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :event_signups, :user_id, algorithm: :concurrently unless index_exists?(:event_signups, :user_id)
    add_index :event_signups, :event_id, algorithm: :concurrently unless index_exists?(:event_signups, :event_id)
    add_index :event_signups, [:user_id, :event_id], unique: true, algorithm: :concurrently unless index_exists?(:event_signups, [:user_id, :event_id])
    add_index :event_signups, :notified_1_day_before, algorithm: :concurrently unless index_exists?(:event_signups, :notified_1_day_before)
    add_index :event_signups, :notified_1_hour_before, algorithm: :concurrently unless index_exists?(:event_signups, :notified_1_hour_before)
  end

  def down
    remove_index :event_signups, :user_id, algorithm: :concurrently if index_exists?(:event_signups, :user_id)
    remove_index :event_signups, :event_id, algorithm: :concurrently if index_exists?(:event_signups, :event_id)
    remove_index :event_signups, [:user_id, :event_id], algorithm: :concurrently if index_exists?(:event_signups, [:user_id, :event_id])
    remove_index :event_signups, :notified_1_day_before, algorithm: :concurrently if index_exists?(:event_signups, :notified_1_day_before)
    remove_index :event_signups, :notified_1_hour_before, algorithm: :concurrently if index_exists?(:event_signups, :notified_1_hour_before)
  end
end
