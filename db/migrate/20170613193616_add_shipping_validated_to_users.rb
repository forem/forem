class AddShippingValidatedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :shipping_validated, :boolean, default: false
  end
end
