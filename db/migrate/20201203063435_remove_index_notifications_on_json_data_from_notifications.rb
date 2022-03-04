class RemoveIndexNotificationsOnJsonDataFromNotifications < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    return unless index_exists?(:notifications, :json_data)

    remove_index :notifications, column: :json_data, algorithm: :concurrently
  end

  def down
    return if index_exists?(:notifications, :json_data)

    add_index :notifications, :json_data, algorithm: :concurrently, using: :gin
  end
end
