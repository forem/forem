class AddLastActiveAtToBroadcasts < ActiveRecord::Migration[6.0]
  def change
    add_column :broadcasts, :last_active_at, :datetime
  end
end
