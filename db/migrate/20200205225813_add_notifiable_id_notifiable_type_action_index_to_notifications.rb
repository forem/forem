class AddNotifiableIdNotifiableTypeActionIndexToNotifications < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :notifications, %i[notifiable_id notifiable_type action],
              unique: false,
              name: "index_notifications_on_notifiable_id_notifiable_type_and_action",
              algorithm: :concurrently
  end
end
