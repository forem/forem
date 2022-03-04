class AddActiveStatusUpdatedAtToBroadcasts < ActiveRecord::Migration[6.0]
  def change
    add_column :broadcasts, :active_status_updated_at, :datetime
  end
end
