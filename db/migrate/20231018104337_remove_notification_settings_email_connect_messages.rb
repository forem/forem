class RemoveNotificationSettingsEmailConnectMessages < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :users_notification_settings, :email_connect_messages
    end
  end
end
