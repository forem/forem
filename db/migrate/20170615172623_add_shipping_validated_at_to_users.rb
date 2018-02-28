class AddShippingValidatedAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :shipping_validated_at, :datetime
  end
end
