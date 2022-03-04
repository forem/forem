class AddUniqueIndexToProfiles < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    remove_index :profiles, column: :user_id, algorithm: :concurrently
    add_index :profiles, :user_id, unique: true, algorithm: :concurrently
  end
end
