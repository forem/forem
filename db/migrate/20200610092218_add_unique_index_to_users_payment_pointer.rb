class AddUniqueIndexToUsersPaymentPointer < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :users, :payment_pointer, unique: true, algorithm: :concurrently
  end
end
