class CreateNotificationSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :notification_subscriptions do |t|
      t.bigint :user_id, null: false
      t.bigint :notifiable_id, null: false
      t.string :notifiable_type, null: false

      t.timestamps
    end
  end
end
