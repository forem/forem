class Rpush310AddPushy < ActiveRecord::Migration[5.0]
  def self.up
    add_column :rpush_notifications, :external_device_id, :string, null: true
  end

  def self.down
    remove_column :rpush_notifications, :external_device_id
  end
end
