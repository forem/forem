class ChangeDevicesAppBundleAndAddReference < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :devices, :app_integration, index: {algorithm: :concurrently}

    # Allow app_bundle null values and remove composite index
    change_column_null :devices, :app_bundle, true
    remove_index :devices, name: "index_devices_on_user_id_and_token_and_platform_and_app_bundle", algorithm: :concurrently

    # Add new composite index using the new reference
    add_index :devices, [:user_id, :token, :platform, :app_integration_id], name: "index_devices_on_user_id_and_token_and_platform_and_app", unique: true, algorithm: :concurrently
  end
end
