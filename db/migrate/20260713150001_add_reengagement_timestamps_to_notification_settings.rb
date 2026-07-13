class AddReengagementTimestampsToNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :users_notification_settings, :email_reengagement_confirmed_at, :datetime
    add_column :users_notification_settings, :email_reengagement_pruned_at, :datetime
  end
end
