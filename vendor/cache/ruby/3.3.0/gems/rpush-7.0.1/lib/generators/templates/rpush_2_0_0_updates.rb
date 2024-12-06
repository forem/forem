class Rpush200Updates < ActiveRecord::Migration[5.0]
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
    add_column :rpush_notifications, :processing, :boolean, null: false, default: false
    add_column :rpush_notifications, :priority, :integer, null: true

    if index_name_exists?(:rpush_notifications, :index_rpush_notifications_multi)
      remove_index :rpush_notifications, name: :index_rpush_notifications_multi
    end

    add_index :rpush_notifications, [:delivered, :failed], name: 'index_rpush_notifications_multi', where: 'NOT delivered AND NOT failed'

    rename_column :rpush_feedback, :app, :app_id

    if postgresql?
      execute('ALTER TABLE rpush_feedback ALTER COLUMN app_id TYPE integer USING (trim(app_id)::integer)')
    else
      change_column :rpush_feedback, :app_id, :integer
    end

    [:Apns, :Gcm, :Wpns, :Adm].each do |service|
      update_type(Rpush200Updates::Rpush::App, "Rpush::#{service}::App", "Rpush::Client::ActiveRecord::#{service}::App")
      update_type(Rpush200Updates::Rpush::Notification, "Rpush::#{service}::Notification", "Rpush::Client::ActiveRecord::#{service}::Notification")
    end
  end

  def self.down
    [:Apns, :Gcm, :Wpns, :Adm].each do |service|
      update_type(Rpush200Updates::Rpush::App, "Rpush::Client::ActiveRecord::#{service}::App", "Rpush::#{service}::App")
      update_type(Rpush200Updates::Rpush::Notification, "Rpush::Client::ActiveRecord::#{service}::Notification", "Rpush::#{service}::Notification")
    end

    change_column :rpush_feedback, :app_id, :string
    rename_column :rpush_feedback, :app_id, :app

    if index_name_exists?(:rpush_notifications, :index_rpush_notifications_multi)
      remove_index :rpush_notifications, name: :index_rpush_notifications_multi
    end

    add_index :rpush_notifications, [:app_id, :delivered, :failed, :deliver_after], name: 'index_rpush_notifications_multi'

    remove_column :rpush_notifications, :priority
    remove_column :rpush_notifications, :processing
  end

  def self.adapter_name
    env = (defined?(Rails) && Rails.env) ? Rails.env : 'development'
    if ActiveRecord::VERSION::MAJOR > 6
      ActiveRecord::Base.configurations.configs_for(env_name: env).first.configuration_hash[:adapter]
    else
      Hash[ActiveRecord::Base.configurations[env].map { |k,v| [k.to_sym,v] }][:adapter]
    end
  end

  def self.postgresql?
    adapter_name =~ /postgresql|postgis/
  end
end
