class AddTypeOfToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :users, :type_of, :integer, default: 0, null: false
    add_index :users, :type_of, algorithm: :concurrently
  end
end
