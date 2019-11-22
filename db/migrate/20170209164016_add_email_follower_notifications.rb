class AddEmailFollowerNotifications < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :email_follower_notifications, :boolean, default: true
  end
end
