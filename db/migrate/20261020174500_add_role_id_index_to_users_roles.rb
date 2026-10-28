class AddRoleIdIndexToUsersRoles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :users_roles, :role_id, algorithm: :concurrently, if_not_exists: true
  end
end
