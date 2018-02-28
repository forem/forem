class AddNotificationReminderEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email_unread_notifications, :boolean, default:true
  end
end
