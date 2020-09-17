class DropPushNotificationSubscriptions < ActiveRecord::Migration[5.2]
  def change
    drop_table :push_notification_subscriptions do |t|
      t.string :endpoint
      t.string :p256dh_key
      t.string :auth_key
      t.string :notification_type
      t.references :user, foreign_key: true, null: false
      t.timestamps
    end
  end
end
