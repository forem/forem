class RemoveBufferUpdates < ActiveRecord::Migration[6.0]
  def change
    drop_table :buffer_updates
  end
end
