class AddCreatedAtIndexToNotifications < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :notifications, :created_at, algorithm: :concurrently
  end
end
