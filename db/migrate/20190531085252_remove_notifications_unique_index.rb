class RemoveNotificationsUniqueIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :notifications, column: %i[user_id organization_id notifiable_id notifiable_type action],
                                 unique: true,
                                 name: "index_notifications_on_user_organization_notifiable_and_action"
  end
end
