class CreateRapnsNotifications < ActiveRecord::Migration[5.0]
  def self.up
    create_table :rapns_notifications do |t|
      t.integer   :badge,                 null: true
      t.string    :device_token,          null: false, limit: 64
      t.string    :sound,                 null: true,  default: "1.aiff"
      t.string    :alert,                 null: true
      t.text      :attributes_for_device, null: true
      t.integer   :expiry,                null: false, default: 1.day.to_i
      t.boolean   :delivered,             null: false, default: false
      t.timestamp :delivered_at,          null: true
      t.boolean   :failed,                null: false, default: false
      t.timestamp :failed_at,             null: true
      t.integer   :error_code,            null: true
      t.string    :error_description,     null: true
      t.timestamp :deliver_after,         null: true
      t.timestamps
    end

    add_index :rapns_notifications, [:delivered, :failed, :deliver_after], name: 'index_rapns_notifications_multi'
  end

  def self.down
    if index_name_exists?(:rapns_notifications, 'index_rapns_notifications_multi')
      remove_index :rapns_notifications, name: 'index_rapns_notifications_multi'
    end

    drop_table :rapns_notifications
  end
end
