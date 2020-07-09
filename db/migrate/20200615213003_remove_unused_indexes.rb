class RemoveUnusedIndexes < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    if index_exists?(:page_views, :domain)
      remove_index :page_views, column: :domain, algorithm: :concurrently
    end

    if index_exists?(:notifications, :notifiable_id)
      remove_index :notifications, column: :notifiable_id, algorithm: :concurrently
    end

    if index_exists?(:users, :old_username)
      remove_index :users, column: :old_username, algorithm: :concurrently
    end
  end

  def down
    if !index_exists?(:page_views, :domain)
      add_index :page_views, :domain, algorithm: :concurrently
    end

    if !index_exists?(:notifications, :notifiable_id)
      add_index :notifications, :notifiable_id, algorithm: :concurrently
    end

    if !index_exists?(:users, :old_username)
      add_index :users, :old_username, algorithm: :concurrently
    end
  end
end
