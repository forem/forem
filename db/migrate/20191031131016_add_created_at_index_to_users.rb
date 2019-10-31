class AddCreatedAtIndexToUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :created_at, algorithm: :concurrently
  end
end
