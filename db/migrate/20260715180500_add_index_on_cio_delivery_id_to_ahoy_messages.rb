class AddIndexOnCioDeliveryIdToAhoyMessages < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :ahoy_messages,
              :cio_delivery_id,
              algorithm: :concurrently
  end
end
