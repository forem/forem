class AddSubPermissionsToUsersRoles < ActiveRecord::Migration[8.0]
  def change
    add_column :users_roles, :sub_permissions, :jsonb
  end
end
