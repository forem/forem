class AddLastNotificationActivityToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :last_notification_activity, :datetime
  end
end
