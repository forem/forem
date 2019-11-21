class AddShippingValidatedToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :shipping_validated, :boolean, default: false
  end
end
