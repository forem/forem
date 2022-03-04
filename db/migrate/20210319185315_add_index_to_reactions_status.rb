class AddIndexToReactionsStatus < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :reactions, :status, algorithm: :concurrently
  end
end
