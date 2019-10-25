class AddOldUsernameIndexToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :users, :old_username, algorithm: :concurrently
    add_index :users, :old_old_username, algorithm: :concurrently
  end
end
