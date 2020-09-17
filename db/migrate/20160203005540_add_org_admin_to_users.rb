class AddOrgAdminToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :org_admin, :boolean, default: false
  end
end
