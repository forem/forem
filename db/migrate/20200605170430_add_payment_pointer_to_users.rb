class AddPaymentPointerToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :payment_pointer, :string
  end
end
