class AddUniqueUserIdIndexToUsersSettings < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :users_settings, :user_id, unique: true, algorithm: :concurrently
  end
end
