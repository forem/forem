class AddDevicesReferenceAndUpdateCompositeIndex < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :devices, :consumer_app, index: {algorithm: :concurrently}

    # Remove old composite index
    remove_index :devices, name: "index_devices_on_user_id_and_token_and_platform_and_app_bundle", algorithm: :concurrently

    # Add new composite index using the new reference consumer_app_id
    add_index :devices, [:user_id, :token, :platform, :consumer_app_id], name: "index_devices_on_user_id_and_token_and_platform_and_app", unique: true, algorithm: :concurrently
  end
end
