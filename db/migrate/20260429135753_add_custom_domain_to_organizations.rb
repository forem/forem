class AddCustomDomainToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :organizations, :custom_domain, :string
    add_index :organizations, :custom_domain,
              unique: true,
              where: "custom_domain IS NOT NULL AND custom_domain <> ''",
              algorithm: :concurrently
  end
end
