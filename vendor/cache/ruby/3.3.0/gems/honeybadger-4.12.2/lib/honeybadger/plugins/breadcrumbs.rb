require 'honeybadger/plugin'
require 'honeybadger/breadcrumbs/logging'

module Honeybadger
  module Plugins
    # @api private
    #
    # This plugin pounces on the dynamic nature of Ruby / Rails to inject into
    # the runtime and provide automatic breadcrumb events.
    #
    # === Log events
    #
    # All log messages within the execution path will automatically be appened
    # to the breadcrumb trace. You can disable all log events in the
    # Honeybadger config:
    #
    # @example
    #
    #   Honeybadger.configure do |config|
    #     config.breadcrumbs.logging.enabled = false
    #   end
    #
    # === ActiveSupport Breadcrumbs
    #
    # We hook into Rails's ActiveSupport Instrumentation system to provide
    # automatic breadcrumb event generation. You can customize these events by
    # passing a Hash into the honeybadger configuration. The simplest method is
    # to alter the current defaults:
    #
    # @example
    #   notifications = Honeybadger::Breadcrumbs::ActiveSupport.default_notifications
    #   notifications.delete("sql.active_record")
    #   notifications["enqueue.active_job"][:exclude_when] = lambda do |data|
    #     data[:job].topic == "salmon_activity"
    #   end
    #
    #   Honeybadger.configure do |config|
    #     config.breadcrumbs.active_support_notifications = notifications
    #   end
    #
    # See RailsBreadcrumbs.send_breadcrumb_notification for specifics on the
    # options for customization
    Plugin.register :breadcrumbs do
      requirement { config[:'breadcrumbs.enabled'] }

      execution do
        # Rails specific breadcrumb events
        #
        if defined?(::Rails.application) && ::Rails.application
          config[:'breadcrumbs.active_support_notifications'].each do |name, config|
            RailsBreadcrumbs.subscribe_to_notification(name, config)
          end
          ActiveSupport::LogSubscriber.prepend(Honeybadger::Breadcrumbs::LogSubscriberInjector) if config[:'breadcrumbs.logging.enabled']
        end

        ::Logger.prepend(Honeybadger::Breadcrumbs::LogWrapper) if config[:'breadcrumbs.logging.enabled']
      end
    end

    class RailsBreadcrumbs
      # @api private
      # Used internally for sending out Rails Instrumentation breadcrumbs.
      #
      # @param [String] name The ActiveSupport instrumentation key
      # @param [Number] duration The time spent in the instrumentation event
      # @param [Hash] notification_config The instrumentation event configuration
      # @param [Hash] data Custom metadata from the instrumentation event
      #
      # @option notification_config [String | Proc] :message A message that describes the event. You can dynamically build the message by passing a proc that accepts the event metadata.
      # @option notification_config [Symbol] :category A key to group specific types of events
      # @option notification_config [Array] :select_keys A set of keys that filters what data we select from the instrumentation data (optional)
      # @option notification_config [Proc] :exclude_when A proc that accepts the data payload. A truthy return value will exclude this event from the payload (optional)
      # @option notification_config [Proc] :transform A proc that accepts the data payload. The return value will replace the current data hash (optional)
      #
      def self.send_breadcrumb_notification(name, duration, notification_config, data = {})
        return if notification_config[:exclude_when] && notification_config[:exclude_when].call(data)

        message =
          case (m = notification_config[:message])
          when Proc
            m.call(data)
          when String
            m
          else
            name
          end

        data = data.slice(*notification_config[:select_keys]) if notification_config[:select_keys]
        data = notification_config[:transform].call(data) if notification_config[:transform]
        data = data.is_a?(Hash) ? data : {}

        data[:duration] = duration if duration

        Honeybadger.add_breadcrumb(
          message,
          category: notification_config[:category] || :custom,
          metadata: data
        )
      end

      # @api private
      def self.subscribe_to_notification(name, notification_config)
        ActiveSupport::Notifications.subscribe(name) do |_, started, finished, _, data|
          duration = finished - started if finished && started

          send_breadcrumb_notification(name, duration, notification_config, data)
        end
      end
    end
  end
end
