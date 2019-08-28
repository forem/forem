class AddNotificationsOrganizationIdIndex < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :notifications, :organization_id, algorithm: :concurrently
  end
end
