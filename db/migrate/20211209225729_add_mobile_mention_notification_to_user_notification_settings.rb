class AddMobileMentionNotificationToUserNotificationSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :users_notification_settings, :mobile_mention_notifications, :boolean, default: true, null: false
  end
end
