class AddPolymorphismToBroadcasts < ActiveRecord::Migration[6.0]
  def change
    add_column :broadcasts, :broadcastable_id, :integer
    add_column :broadcasts, :broadcastable_type, :string
  end
end
