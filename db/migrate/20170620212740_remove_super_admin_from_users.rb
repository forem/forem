class RemoveSuperAdminFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :super_admin
  end
end
