class AddUserIdAndCreatedAtToNotifications < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"

      if index_exists?(:notifications, [:user_id, :created_at])
        remove_index :notifications, [:user_id, :created_at], algorithm: :concurrently
      end

      add_index :notifications, [:user_id, :created_at], algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"

      if index_exists?(:notifications, [:user_id, :created_at])
        remove_index :notifications, [:user_id, :created_at], algorithm: :concurrently
      end
    end
  end
end
