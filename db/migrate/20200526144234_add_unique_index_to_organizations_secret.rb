class AddUniqueIndexToOrganizationsSecret < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :organizations, :secret, unique: true, algorithm: :concurrently
  end
end
