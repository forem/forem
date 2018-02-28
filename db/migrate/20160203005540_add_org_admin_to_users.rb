class AddOrgAdminToUsers < ActiveRecord::Migration
  def change
    add_column :users, :org_admin, :boolean, default: false
  end
end
