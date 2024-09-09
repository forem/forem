class AddRoleNamesToBillboards < ActiveRecord::Migration[7.0]
  def change
    add_column :display_ads, :exclude_role_names, :string, array: true, default: []
    add_column :display_ads, :target_role_names, :string, array: true, default: []
  end
end
