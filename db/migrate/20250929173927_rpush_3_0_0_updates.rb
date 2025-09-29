class Rpush300Updates < ActiveRecord::Migration[5.0]
  def self.up
    add_column :rpush_notifications, :mutable_content, :boolean, default: false
    change_column :rpush_notifications, :sound, :string, default: nil
  end

  def self.down
    remove_column :rpush_notifications, :mutable_content
    change_column :rpush_notifications, :sound, :string, default: 'default'
  end
end
