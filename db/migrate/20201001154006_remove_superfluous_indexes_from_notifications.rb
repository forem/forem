class RemoveSuperfluousIndexesFromNotifications < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    if index_exists?(:notifications, :organization_id)
      remove_index :notifications, column: :organization_id, algorithm: :concurrently
    end

    if index_exists?(:notifications, :user_id)
      remove_index :notifications, column: :user_id, algorithm: :concurrently
    end
  end

  def down
    unless index_exists?(:notifications, :organization_id)
      add_index :notifications, :organization_id, algorithm: :concurrently
    end

    unless index_exists?(:notifications, :user_id)
      add_index :notifications, :user_id, algorithm: :concurrently
    end
  end
end
