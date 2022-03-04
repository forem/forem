class AddColumnsToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_index :notifications, :notifiable_id
    add_index :notifications, :user_id
    add_index :notifications, :notifiable_type
    add_column :notifications, :json_data, :jsonb
    add_index :notifications, :json_data, using: :gin
    add_column :notifications, :read?, :boolean, default: false
  end
end
