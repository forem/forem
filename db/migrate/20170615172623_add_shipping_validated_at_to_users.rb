class AddShippingValidatedAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :shipping_validated_at, :datetime
  end
end
