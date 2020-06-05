class AddUniqueIndexToNotificationsUserIdOrganizationIdNotifiableAction < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    return if index_exists?(
      :notifications,
      %i[user_id organization_id notifiable_id notifiable_type action],
      name: :index_notifications_user_id_organization_id_notifiable_action
    )

    add_index(
      :notifications,
      %i[user_id organization_id notifiable_id notifiable_type action],
      unique: true,
      algorithm: :concurrently,
      name: :index_notifications_user_id_organization_id_notifiable_action
    )
  end
end
