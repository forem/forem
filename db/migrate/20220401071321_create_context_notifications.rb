class CreateContextNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :context_notifications do |t|
      t.string :action
      t.integer :context_id
      t.string :context_type

      t.timestamps
    end
    add_index :context_notifications, %i[context_id context_type action],
              unique: true, name: "index_context_notification_on_context_and_action"
  end
end
