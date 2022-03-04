class CreatePushNotificationSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :push_notification_subscriptions do |t|
      t.string :endpoint
      t.string :p256dh_key
      t.string :auth_key
      t.string :notification_type
      t.references :user, foreign_key: true, null: false
      t.timestamps
    end
  end
end