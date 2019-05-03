class AddUniqueIndexToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_index :notifications, %i[user_id organization_id notifiable_id notifiable_type action], unique: true, name: "index_notifications_on_user_organization_notifiable_and_action"
  end
end
