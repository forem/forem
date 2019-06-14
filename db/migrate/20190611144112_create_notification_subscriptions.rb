class CreateNotificationSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :notification_subscriptions do |t|
      t.bigint :user_id, null: false
      t.bigint :notifiable_id, null: false
      t.string :notifiable_type, null: false
      t.text :config, null: false, default: "all_comments"

      t.timestamps
    end
    add_index :notification_subscriptions, %i[notifiable_id notifiable_type config], name: "index_notification_subscriptions_on_notifiable_and_config"
  end
end
