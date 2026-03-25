class AddScoreIndexToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :users, :score, algorithm: :concurrently
  end
end
