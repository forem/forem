class CreatePushNotificationTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :push_notification_targets do |t|
      t.string :app_bundle, null: false, index: true
      t.string :platform, null: false
      t.boolean :active, null: false
      t.string :auth_key
      t.timestamps
    end
  end
end
