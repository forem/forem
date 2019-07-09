class AddIndexToCreditsSpent < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :credits, :spent, algorithm: :concurrently
  end
end
