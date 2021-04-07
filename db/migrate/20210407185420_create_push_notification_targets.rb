class CreatePushNotificationTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :push_notification_targets do |t|
      t.string :app_bundle, null: false, index: true
      t.string :auth_key
      t.string :platform, null: false
      t.boolean :enabled, null: false
      t.timestamps
    end
  end
end
