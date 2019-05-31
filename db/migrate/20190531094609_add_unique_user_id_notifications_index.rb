class AddUniqueUserIdNotificationsIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :notifications, %i[user_id notifiable_id notifiable_type action],
              where: "action IS NOT NULL",
              unique: true,
              name: "index_notifications_on_user_notifiable_and_action_not_null"
    add_index :notifications, %i[user_id notifiable_id notifiable_type],
              where: "action IS NULL",
              unique: true,
              name: "index_notifications_on_user_notifiable_action_is_null"
  end
end
