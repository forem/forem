class AddIndexToUsersAppleUsername < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :users, :apple_username, algorithm: :concurrently
  end
end
