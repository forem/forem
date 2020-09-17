class RemoveSuperAdminFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :super_admin
  end
end
