class AddUniqueIndexToWebhookEndpointsTargetUrl < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :webhook_endpoints, :target_url, unique: true, algorithm: :concurrently
  end
end
