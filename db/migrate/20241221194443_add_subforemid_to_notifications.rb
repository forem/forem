class AddSubforemidToNotifications < ActiveRecord::Migration[7.0]
  def change
    add_column :notifications, :subforem_id, :bigint
  end
end
