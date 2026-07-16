class AddCioDeliveryIdToAhoyMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :ahoy_messages, :cio_delivery_id, :string
  end
end
