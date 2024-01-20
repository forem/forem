class AddNewPostNotificationsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users_notification_settings, :new_post_notifications, :boolean, default: true, null: false
  end
end