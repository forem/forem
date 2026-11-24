class CreateAdminNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_notifications, &:timestamps
  end
end
