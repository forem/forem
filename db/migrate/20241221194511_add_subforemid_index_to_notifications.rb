class AddSubforemidIndexToNotifications < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :notifications, :subforem_id, algorithm: :concurrently
  end
end
