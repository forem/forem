class AddSuperAdminToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :super_admin, :boolean, default: false
  end
end
