class AddIndexToNotificationsNotifiedAt < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :notifications, :notified_at, algorithm: :concurrently
  end
end
