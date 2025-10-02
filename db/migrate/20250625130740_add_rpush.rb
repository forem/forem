# NOTE TO THE CURIOUS.
#
# Congratulations on being a diligent developer and vetting the migrations
# added to your project!
#
# You're probably thinking "This migration is huge!". It is, but that doesn't
# mean it'll take a long time to run, or that the reason for it being
# this size is because of lousy developers.
#
# Rpush used to be known as Rapns. In an effort to reduce clutter in db/migrate
# for new users of Rpush, what you see below is a concatenation of the
# migrations added to Rapns over its lifetime.
#
# The reason for concatenating old migrations - instead of producing a new
# one that attempts to recreate their accumulative state - is that I don't
# want to introduce any bugs by writing a new migration.
#
# So while this looks like a scary amount of code, it is in fact the safest
# approach. The constituent parts of this migration have been executed
# many times, by many people!

class AddRpush < ActiveRecord::Migration[5.0]
  def self.migrations
    [CreateRapnsNotifications, CreateRapnsFeedback,
     AddAlertIsJsonToRapnsNotifications, AddAppToRapns,
     CreateRapnsApps, AddGcm, AddWpns, AddAdm, RenameRapnsToRpush,
     AddFailAfterToRpushNotifications]
  end

  def self.up
    migrations.map(&:up)
  end

  def self.down
    migrations.reverse.each do |m|
      begin
        m.down
      rescue ActiveRecord::StatementInvalid => e
        p e
      end
    end
  end

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

  class CreateRapnsFeedback < ActiveRecord::Migration[5.0]
    def self.up
      create_table :rapns_feedback do |t|
        t.string    :device_token,          null: false, limit: 64
        t.timestamp :failed_at,             null: false
        t.timestamps
      end

      add_index :rapns_feedback, :device_token
    end

    def self.down
      if index_name_exists?(:rapns_feedback, :index_rapns_feedback_on_device_token)
        remove_index :rapns_feedback, name: :index_rapns_feedback_on_device_token
      end

      drop_table :rapns_feedback
    end
  end

  class AddAlertIsJsonToRapnsNotifications < ActiveRecord::Migration[5.0]
    def self.up
      add_column :rapns_notifications, :alert_is_json, :boolean, null: true, default: false
    end

    def self.down
      remove_column :rapns_notifications, :alert_is_json
    end
  end

  class AddAppToRapns < ActiveRecord::Migration[5.0]
    def self.up
      add_column :rapns_notifications, :app, :string, null: true
      add_column :rapns_feedback, :app, :string, null: true
    end

    def self.down
      remove_column :rapns_notifications, :app
      remove_column :rapns_feedback, :app
    end
  end

  class CreateRapnsApps < ActiveRecord::Migration[5.0]
    def self.up
      create_table :rapns_apps do |t|
        t.string    :key,             null: false
        t.string    :environment,     null: false
        t.text      :certificate,     null: false
        t.string    :password,        null: true
        t.integer   :connections,     null: false, default: 1
        t.timestamps
      end
    end

    def self.down
      drop_table :rapns_apps
    end
  end

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
        AddGcm::Rapns::Notification.where(app: app.name).update_all(app_id: app.id)
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
        AddGcm::Rapns::Notification.where(app_id: app.id).update_all(app: app.key)
      end

      if index_name_exists?(:rapns_notifications, :index_rapns_notifications_multi)
        remove_index :rapns_notifications, name: :index_rapns_notifications_multi
      end

      remove_column :rapns_notifications, :app_id

      add_index :rapns_notifications, [:delivered, :failed, :deliver_after], name: :index_rapns_notifications_multi
    end
  end

  class AddWpns < ActiveRecord::Migration[5.0]
    module Rapns
      class Notification < ActiveRecord::Base
        self.table_name = 'rapns_notifications'
      end
    end

    def self.up
      add_column :rapns_notifications, :uri, :string, null: true
    end

    def self.down
      AddWpns::Rapns::Notification.where(type: 'Rapns::Wpns::Notification').delete_all
      remove_column :rapns_notifications, :uri
    end
  end

  class AddAdm < ActiveRecord::Migration[5.0]
    module Rapns
      class Notification < ActiveRecord::Base
        self.table_name = 'rapns_notifications'
      end
    end

    def self.up
      add_column :rapns_apps, :client_id, :string, null: true
      add_column :rapns_apps, :client_secret, :string, null: true
      add_column :rapns_apps, :access_token, :string, null: true
      add_column :rapns_apps, :access_token_expiration, :datetime, null: true
    end

    def self.down
      AddAdm::Rapns::Notification.where(type: 'Rapns::Adm::Notification').delete_all

      remove_column :rapns_apps, :client_id
      remove_column :rapns_apps, :client_secret
      remove_column :rapns_apps, :access_token
      remove_column :rapns_apps, :access_token_expiration
    end
  end

  class RenameRapnsToRpush < ActiveRecord::Migration[5.0]
    module Rpush
      class App < ActiveRecord::Base
        self.table_name = 'rpush_apps'
      end

      class Notification < ActiveRecord::Base
        self.table_name = 'rpush_notifications'
      end
    end

    def self.update_type(model, from, to)
      model.where(type: from).update_all(type: to)
    end

    def self.up
      rename_table :rapns_notifications, :rpush_notifications
      rename_table :rapns_apps, :rpush_apps
      rename_table :rapns_feedback, :rpush_feedback

      if index_name_exists?(:rpush_notifications, :index_rapns_notifications_multi)
        rename_index :rpush_notifications, :index_rapns_notifications_multi, :index_rpush_notifications_multi
      end

      if index_name_exists?(:rpush_feedback, :index_rapns_feedback_on_device_token)
        rename_index :rpush_feedback, :index_rapns_feedback_on_device_token, :index_rpush_feedback_on_device_token
      end

      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rapns::Apns::Notification', 'Rpush::Apns::Notification')
      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rapns::Gcm::Notification', 'Rpush::Gcm::Notification')
      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rapns::Adm::Notification', 'Rpush::Adm::Notification')
      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rapns::Wpns::Notification', 'Rpush::Wpns::Notification')

      update_type(RenameRapnsToRpush::Rpush::App, 'Rapns::Apns::App', 'Rpush::Apns::App')
      update_type(RenameRapnsToRpush::Rpush::App, 'Rapns::Gcm::App', 'Rpush::Gcm::App')
      update_type(RenameRapnsToRpush::Rpush::App, 'Rapns::Adm::App', 'Rpush::Adm::App')
      update_type(RenameRapnsToRpush::Rpush::App, 'Rapns::Wpns::App', 'Rpush::Wpns::App')
    end

    def self.down
      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rpush::Apns::Notification', 'Rapns::Apns::Notification')
      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rpush::Gcm::Notification', 'Rapns::Gcm::Notification')
      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rpush::Adm::Notification', 'Rapns::Adm::Notification')
      update_type(RenameRapnsToRpush::Rpush::Notification, 'Rpush::Wpns::Notification', 'Rapns::Wpns::Notification')

      update_type(RenameRapnsToRpush::Rpush::App, 'Rpush::Apns::App', 'Rapns::Apns::App')
      update_type(RenameRapnsToRpush::Rpush::App, 'Rpush::Gcm::App', 'Rapns::Gcm::App')
      update_type(RenameRapnsToRpush::Rpush::App, 'Rpush::Adm::App', 'Rapns::Adm::App')
      update_type(RenameRapnsToRpush::Rpush::App, 'Rpush::Wpns::App', 'Rapns::Wpns::App')

      if index_name_exists?(:rpush_notifications, :index_rpush_notifications_multi)
        rename_index :rpush_notifications, :index_rpush_notifications_multi, :index_rapns_notifications_multi
      end

      if index_name_exists?(:rpush_feedback, :index_rpush_feedback_on_device_token)
        rename_index :rpush_feedback, :index_rpush_feedback_on_device_token, :index_rapns_feedback_on_device_token
      end

      rename_table :rpush_notifications, :rapns_notifications
      rename_table :rpush_apps, :rapns_apps
      rename_table :rpush_feedback, :rapns_feedback
    end
  end

  class AddFailAfterToRpushNotifications < ActiveRecord::Migration[5.0]
    def self.up
      add_column :rpush_notifications, :fail_after, :timestamp, null: true
    end

    def self.down
      remove_column :rpush_notifications, :fail_after
    end
  end
end
