class RemoveUserShippingFields < ActiveRecord::Migration[5.2]
  def change
    safety_assured {
      remove_column :users, :shipping_name, :string
      remove_column :users, :shipping_company, :string
      remove_column :users, :shipping_address, :string
      remove_column :users, :shipping_address_line_2, :string
      remove_column :users, :shipping_city, :string
      remove_column :users, :shipping_state, :string
      remove_column :users, :shipping_country, :string
      remove_column :users, :shipping_postal_code, :string
    }
  end
end
