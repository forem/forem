class AddEmailFollowerNotifications < ActiveRecord::Migration
  def change
    add_column :users, :email_follower_notifications, :boolean, default: true
  end
end
