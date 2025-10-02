class Rpush301Updates < ActiveRecord::Migration[5.0]
  def self.up
    change_column_null :rpush_notifications, :mutable_content, false
    change_column_null :rpush_notifications, :content_available, false
    change_column_null :rpush_notifications, :alert_is_json, false
  end

  def self.down
    change_column_null :rpush_notifications, :mutable_content, true
    change_column_null :rpush_notifications, :content_available, true
    change_column_null :rpush_notifications, :alert_is_json, true
  end
end
