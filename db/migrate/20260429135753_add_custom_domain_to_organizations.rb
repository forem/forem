class AddCustomDomainToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :organizations, :custom_domain, :string
    add_index :organizations, :custom_domain, unique: true, algorithm: :concurrently
  end
end
