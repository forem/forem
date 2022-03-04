class AddActiveToBroadcasts < ActiveRecord::Migration[5.2]
  def change
    add_column :broadcasts, :active, :boolean, default: false
  end
end
