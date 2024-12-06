module Rpush
  module Daemon
    class Synchronizer
      extend Loggable
      extend StringHelpers

      APP_ATTRIBUTES_TO_CHECK = [:certificate, :environment, :auth_key, :client_id, :client_secret].freeze

      def self.sync
        apps = Rpush::Daemon.store.all_apps
        apps.each { |app| sync_app(app) }
        removed = AppRunner.app_ids - apps.map(&:id)
        removed.each { |app_id| AppRunner.stop_app(app_id) }

        ProcTitle.update
      end

      def self.sync_app(app)
        if !AppRunner.app_running?(app)
          AppRunner.start_app(app)
        elsif (changed_attrs = changed_attributes(app)).count > 0
          changed_attrs_str = changed_attrs.map(&:to_s).join(", ")
          log_info("[#{app.name}] #{changed_attrs_str} changed, restarting...")
          AppRunner.stop_app(app.id)
          AppRunner.start_app(app)
        else
          sync_dispatcher_count(app)
        end
      end

      def self.sync_dispatcher_count(app)
        num_dispatchers = AppRunner.num_dispatchers_for_app(app)
        diff = num_dispatchers - app.connections
        return if diff == 0

        if diff > 0
          AppRunner.decrement_dispatchers(app, diff)
          start_stop_str = "Stopped"
        else
          AppRunner.increment_dispatchers(app, diff.abs)
          start_stop_str = "Started"
        end

        num_dispatchers = AppRunner.num_dispatchers_for_app(app)
        log_info("[#{app.name}] #{start_stop_str} #{pluralize(diff.abs, 'dispatcher')}. #{num_dispatchers} running.")
      end

      def self.changed_attributes(app)
        APP_ATTRIBUTES_TO_CHECK.select { |attr| attribute_changed?(app, attr) }
      end

      def self.attribute_changed?(app, attr)
        if app.respond_to?(attr)
          old_app = AppRunner.app_with_id(app.id)
          app.send(attr) != old_app.send(attr)
        else
          false
        end
      end
    end
  end
end
