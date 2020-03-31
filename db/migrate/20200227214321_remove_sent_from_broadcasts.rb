class RemoveSentFromBroadcasts < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :broadcasts, :sent, :boolean }
  end
end
