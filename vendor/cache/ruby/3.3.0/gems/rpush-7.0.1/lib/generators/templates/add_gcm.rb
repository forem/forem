class AddGcm < ActiveRecord::Migration[5.0]
  module Rapns
    class App < ActiveRecord::Base
      self.table_name = 'rapns_apps'
    end

    class Notification < ActiveRecord::Base
      belongs_to :app
      self.table_name = 'rapns_notifications'
    end
  end

  def self.up
    add_column :rapns_notifications, :type, :string, null: true
    add_column :rapns_apps, :type, :string, null: true

    AddGcm::Rapns::Notification.update_all type: 'Rapns::Apns::Notification'
    AddGcm::Rapns::App.update_all type: 'Rapns::Apns::App'

    change_column :rapns_notifications, :type, :string, null: false
    change_column :rapns_apps, :type, :string, null: false
    change_column :rapns_notifications, :device_token, :string, null: true, limit: 64
    change_column :rapns_notifications, :expiry, :integer, null: true, default: 1.day.to_i
    change_column :rapns_apps, :environment, :string, null: true
    change_column :rapns_apps, :certificate, :text, null: true, default: nil

    change_column :rapns_notifications, :error_description, :text, null: true, default: nil
    change_column :rapns_notifications, :sound, :string, default: 'default'

    rename_column :rapns_notifications, :attributes_for_device, :data
    rename_column :rapns_apps, :key, :name

    add_column :rapns_apps, :auth_key, :string, null: true

    add_column :rapns_notifications, :collapse_key, :string, null: true
    add_column :rapns_notifications, :delay_while_idle, :boolean, null: false, default: false

    reg_ids_type = ActiveRecord::Base.connection.adapter_name.include?('Mysql') ? :mediumtext : :text
    add_column :rapns_notifications, :registration_ids, reg_ids_type, null: true
    add_column :rapns_notifications, :app_id, :integer, null: true
    add_column :rapns_notifications, :retries, :integer, null: true, default: 0

    AddGcm::Rapns::Notification.reset_column_information
    AddGcm::Rapns::App.reset_column_information

    AddGcm::Rapns::App.all.each do |app|
      AddGcm::Rapns::Notification.update_all(['app_id = ?', app.id], ['app = ?', app.name])
    end

    change_column :rapns_notifications, :app_id, :integer, null: false
    remove_column :rapns_notifications, :app

    if index_name_exists?(:rapns_notifications, "index_rapns_notifications_multi")
      remove_index :rapns_notifications, name: "index_rapns_notifications_multi"
    elsif index_name_exists?(:rapns_notifications, "index_rapns_notifications_on_delivered_failed_deliver_after")
      remove_index :rapns_notifications, name: "index_rapns_notifications_on_delivered_failed_deliver_after"
    end

    add_index :rapns_notifications, [:app_id, :delivered, :failed, :deliver_after], name: "index_rapns_notifications_multi"
  end

  def self.down
    AddGcm::Rapns::Notification.where(type: 'Rapns::Gcm::Notification').delete_all

    remove_column :rapns_notifications, :type
    remove_column :rapns_apps, :type

    change_column :rapns_notifications, :device_token, :string, null: false, limit: 64
    change_column :rapns_notifications, :expiry, :integer, null: false, default: 1.day.to_i
    change_column :rapns_apps, :environment, :string, null: false
    change_column :rapns_apps, :certificate, :text, null: false

    change_column :rapns_notifications, :error_description, :string, null: true, default: nil
    change_column :rapns_notifications, :sound, :string, default: '1.aiff'

    rename_column :rapns_notifications, :data, :attributes_for_device
    rename_column :rapns_apps, :name, :key

    remove_column :rapns_apps, :auth_key

    remove_column :rapns_notifications, :collapse_key
    remove_column :rapns_notifications, :delay_while_idle
    remove_column :rapns_notifications, :registration_ids
    remove_column :rapns_notifications, :retries

    add_column :rapns_notifications, :app, :string, null: true

    AddGcm::Rapns::Notification.reset_column_information
    AddGcm::Rapns::App.reset_column_information

    AddGcm::Rapns::App.all.each do |app|
      AddGcm::Rapns::Notification.update_all(['app = ?', app.key], ['app_id = ?', app.id])
    end

    if index_name_exists?(:rapns_notifications, :index_rapns_notifications_multi)
      remove_index :rapns_notifications, name: :index_rapns_notifications_multi
    end

    remove_column :rapns_notifications, :app_id

    add_index :rapns_notifications, [:delivered, :failed, :deliver_after], name: :index_rapns_notifications_multi
  end
end
