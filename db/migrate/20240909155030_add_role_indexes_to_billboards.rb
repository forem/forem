class AddRoleIndexesToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :display_ads, :exclude_role_names, using: 'gin', algorithm: :concurrently
    add_index :display_ads, :target_role_names, using: 'gin', algorithm: :concurrently
  end
end
