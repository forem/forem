class AddUniqueIndexToBroadcastsTitleAndType < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :broadcasts, %i[title broadcastable_type], unique: true, algorithm: :concurrently
  end
end
