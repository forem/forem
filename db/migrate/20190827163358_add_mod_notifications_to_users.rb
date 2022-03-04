class AddModNotificationsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :mod_roundrobin_notifications, :boolean, default: true
  end
end
