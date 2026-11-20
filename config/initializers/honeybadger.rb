# Can be used to implement more programatic error handling
# https://docs.honeybadger.io/lib/ruby/getting-started/ignoring-errors.html#ignore-programmatically

# rubocop:disable Metrics/BlockLength
configure_honeybadger = lambda do
  honeybadger_api_key = ApplicationConfig["HONEYBADGER_API_KEY"].presence

  if honeybadger_api_key
    require "honeybadger"

    message_fingerprints = {
      "Rack::Timeout::RequestTimeoutException" => "rack_timeout",
      "Rack::Timeout::RequestTimeoutError" => "rack_timeout",
      "PG::QueryCanceled" => "pg_query_canceled"
    }

    component_fingerprints = {
      "internal" => "internal"
    }

    honeybadger_exceptions_to_ignore = [
      ActiveRecord::QueryCanceled,
      ActiveRecord::RecordNotFound,
      Pundit::NotAuthorizedError,
      RateLimitChecker::LimitReached,
    ]

    Honeybadger.config.set(:before_notify, [])

    # https://docs.honeybadger.io/lib/ruby/gem-reference/configuration.html
    Honeybadger.configure do |config|
      config.env = "#{ApplicationConfig['APP_DOMAIN']}-#{Rails.env}"
      config.api_key = honeybadger_api_key
      config.revision = ApplicationConfig["RELEASE_FOOTPRINT"]
      config.report_data = !Rails.env.test?
      config.exceptions.enabled = true

      # Prevent Ruby from exiting until all queued notices have been delivered to Honeybadger.
      # When set to true(default), it can lead to a large number of errors causing a process to get stuck.
      # To prevent this we set it to false ensuring that a process can exit quickly regardless of errors.
      # Logging allows us to fill in gaps if we need to when errors get discarded.
      config.send_data_at_exit = false

      config.exceptions.ignore = Honeybadger::Config::DEFAULTS[:"exceptions.ignore"] | honeybadger_exceptions_to_ignore
      config.request.filter_keys = Honeybadger::Config::DEFAULTS[:"request.filter_keys"] | %w[authorization]
      config.sidekiq.attempt_threshold = 10
      # Breadcrumbs subscribe to every ActiveSupport notification, which is pure overhead in tests.
      config.breadcrumbs.enabled = !Rails.env.test?

      config.before_notify do |notice|
        notice.halt! if notice.error_class == "SignalException" && notice.error_message&.include?("SIGHUP")

        notice.fingerprint = if notice.error_message&.include?("SIGTERM") && notice.component&.include?("feeds_import")
                               notice.error_message
                             elsif (msg_key = message_fingerprints.keys.detect do |k, _v|
                                      notice.error_message&.include?(k)
                                    end)
                               message_fingerprints[msg_key]
                             elsif (cmp_key = component_fingerprints.keys.detect do |k, _v|
                                      notice.component&.include?(k)
                                    end)
                               component_fingerprints[cmp_key]
                             end
      end
    end
  elsif defined?(Honeybadger::Agent)
    Honeybadger.config.set(:before_notify, [])
    Honeybadger.configure do |config|
      config.api_key = nil
      config.report_data = false
      config.exceptions.enabled = false
      config.breadcrumbs.enabled = false
    end
  else
    module Honeybadger
      # Uses `extend self` (matching Honeybadger's own singleton.rb) rather than
      # `module_function` so `require "honeybadger"` cleanly replaces these methods.
      extend self # rubocop:disable Style/ModuleFunction

      def notify(*, **)
        false
      end

      def context(_ctx = nil)
        block_given? ? yield : self
      end

      def clear!
        nil
      end

      def add_breadcrumb(*, **)
        nil
      end
    end
  end
end

if Rails.application.initialized?
  configure_honeybadger.call
else
  Rails.application.reloader.to_prepare(&configure_honeybadger)
end
# rubocop:enable Metrics/BlockLength
