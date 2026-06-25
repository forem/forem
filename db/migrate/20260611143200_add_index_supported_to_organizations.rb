class AddIndexSupportedToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :organizations, :supported, algorithm: :concurrently
  end
end
