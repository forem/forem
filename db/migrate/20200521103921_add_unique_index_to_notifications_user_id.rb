class AddUniqueIndexToNotificationsUserId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :notifications,
      %i[user_id organization_id notifiable_id notifiable_type action],
      unique: true,
      algorithm: :concurrently,
      name: :index_notifications_on_user_organization_notifiable_action
    )
  end
end
