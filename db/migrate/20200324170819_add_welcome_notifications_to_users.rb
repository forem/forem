class AddWelcomeNotificationsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :welcome_notifications, :boolean, default: true, null: false
  end
end
