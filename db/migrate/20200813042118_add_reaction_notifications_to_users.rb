class AddReactionNotificationsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :reaction_notifications, :boolean, default: true
  end
end
