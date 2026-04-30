class AddTlsFieldsToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :organizations, :tls_subscription_id, :string
    add_column :organizations, :tls_status, :integer, default: 0, null: false

    add_index :organizations,
              :tls_subscription_id,
              unique: true,
              where: "tls_subscription_id IS NOT NULL AND tls_subscription_id <> ''",
              algorithm: :concurrently
  end
end
