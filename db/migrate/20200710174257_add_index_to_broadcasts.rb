class AddIndexToBroadcasts < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :broadcasts, %i[broadcastable_type broadcastable_id], unique: true, algorithm: :concurrently
  end
end
