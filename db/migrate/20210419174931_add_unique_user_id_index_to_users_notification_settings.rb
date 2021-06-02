class AddUniqueUserIdIndexToUsersNotificationSettings < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :users_notification_settings, :user_id, unique: true, algorithm: :concurrently
  end
end
