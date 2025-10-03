class Rpush331Updates < ActiveRecord::Migration[5.0]
  def self.up
    change_column :rpush_notifications, :device_token, :string, null: true
    change_column :rpush_feedback, :device_token, :string, null: true
  end

  def self.down
    change_column :rpush_notifications, :device_token, :string, null: true, limit: 64
    change_column :rpush_feedback, :device_token, :string, null: true, limit: 64
  end
end
