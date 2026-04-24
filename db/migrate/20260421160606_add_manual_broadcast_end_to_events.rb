class AddManualBroadcastEndToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :manual_broadcast_end, :boolean, default: false, null: false
    add_column :events, :broadcast_ended_at, :datetime
  end
end
