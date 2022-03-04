class RemoveUserIdIndexFromUsersSettings < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    remove_index :users_settings, column: :user_id, algorithm: :concurrently
  end
end
