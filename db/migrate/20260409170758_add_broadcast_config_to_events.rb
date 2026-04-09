class AddBroadcastConfigToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :broadcast_config, :integer, default: 0
  end
end
