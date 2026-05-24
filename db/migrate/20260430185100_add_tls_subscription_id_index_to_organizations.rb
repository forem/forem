class AddTlsSubscriptionIdIndexToOrganizations < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :organizations,
              :tls_subscription_id,
              unique: true,
              where: "tls_subscription_id IS NOT NULL AND tls_subscription_id <> ''",
              algorithm: :concurrently
  end
end
