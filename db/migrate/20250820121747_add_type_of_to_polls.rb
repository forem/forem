class AddTypeOfToPolls < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :polls, :type_of, :integer, default: 0, null: false
    add_index :polls, :type_of, algorithm: :concurrently
  end
end
