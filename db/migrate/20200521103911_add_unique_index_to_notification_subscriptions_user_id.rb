class AddUniqueIndexToNotificationSubscriptionsUserId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :notification_subscriptions,
      %i[user_id notifiable_type notifiable_id],
      unique: true,
      algorithm: :concurrently,
      name: :idx_notification_subs_on_user_id_notifiable_type_notifiable_id
    )
  end
end
