class AddLastModerationNotificationToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :last_moderation_notification, :datetime, default: 1.day.ago
  end
end
