require "timber-rails/overrides"

require "timber"
require "rails"
require "timber-rails/active_support_log_subscriber"
require "timber-rails/config"
require "timber-rails/railtie"

require "timber-rack/http_context"
require "timber-rack/http_events"
require "timber-rack/user_context"
require "timber-rails/session_context"
require "timber-rails/rack_logger"
require "timber-rails/error_event"

require "timber-rails/action_controller"
require "timber-rails/action_dispatch"
require "timber-rails/action_view"
require "timber-rails/active_record"


require "timber-rails/logger"

module Timber
  module Integrations
    # Module for holding *all* Rails integrations. This module does *not*
    # extend {Integration} because it's dependent on {Rack::HTTPEvents}. This
    # module simply disables the default HTTP request logging.
    module Rails
      def self.enabled?
        Timber::Integrations::Rack::HTTPEvents.enabled?
      end

      def self.integrate!
        return false if !enabled?

        ActionController.integrate!
        ActionDispatch.integrate!
        ActionView.integrate!
        ActiveRecord.integrate!
        RackLogger.integrate!
      end

      def self.enabled=(value)
        Timber::Integrations::Rails::ErrorEvent.enabled = value
        Timber::Integrations::Rack::HTTPContext.enabled = value
        Timber::Integrations::Rack::HTTPEvents.enabled = value
        Timber::Integrations::Rack::UserContext.enabled = value
        SessionContext.enabled = value

        ActionController.enabled = value
        ActionView.enabled = value
        ActiveRecord.enabled = value
      end

      # All enabled middlewares. The order is relevant. Middlewares that set
      # context are added first so that context is included in subsequent log lines.
      def self.middlewares
        @middlewares ||= [Timber::Integrations::Rack::HTTPContext, SessionContext, Timber::Integrations::Rack::UserContext,
          Timber::Integrations::Rack::HTTPEvents, Timber::Integrations::Rails::ErrorEvent].select(&:enabled?)
      end
    end
  end
end

