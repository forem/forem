# Can be used to implement more programatic error handling
# https://docs.honeybadger.io/lib/ruby/getting-started/ignoring-errors.html#ignore-programmatically

MESSAGE_FINGERPRINTS = {
  "SuspendedError" => "banned",
  "Rack::Timeout::RequestTimeoutException" => "rack_timeout",
  "Rack::Timeout::RequestTimeoutError" => "rack_timeout",
  "PG::QueryCanceled" => "pg_query_canceled"
}.freeze

COMPONENT_FINGERPRINTS = {
  "internal" => "internal"
}.freeze

HONEYBADGER_EXCEPTIONS_TO_IGNORE = [
  ActiveRecord::QueryCanceled,
  ActiveRecord::RecordNotFound,
  Pundit::NotAuthorizedError,
  RateLimitChecker::LimitReached,
].freeze

Rails.application.reloader.to_prepare do
  # https://docs.honeybadger.io/lib/ruby/gem-reference/configuration.html
  Honeybadger.configure do |config|
    config.env = "#{ApplicationConfig['APP_DOMAIN']}-#{Rails.env}"
    config.api_key = ApplicationConfig["HONEYBADGER_API_KEY"]
    config.revision = ApplicationConfig["RELEASE_FOOTPRINT"]

    # Prevent Ruby from exiting until all queued notices have been delivered to Honeybadger.
    # When set to true(default), it can lead to a large number of errors causing a process to get stuck.
    # To prevent this we set it to false ensuring that a process can exit quickly regardless of errors.
    # Logging allows us to fill in gaps if we need to when errors get discarded.
    config.send_data_at_exit = false

    config.exceptions.ignore += HONEYBADGER_EXCEPTIONS_TO_IGNORE
    config.request.filter_keys += %w[authorization]
    config.sidekiq.attempt_threshold = 10
    config.breadcrumbs.enabled = true

    config.before_notify do |notice|
      notice.fingerprint = if notice.error_message&.include?("SIGTERM") && notice.component&.include?("feeds_import")
                             notice.error_message
                           elsif (msg_key = MESSAGE_FINGERPRINTS.keys.detect do |k, _v|
                                    notice.error_message&.include?(k)
                                  end)
                             MESSAGE_FINGERPRINTS[msg_key]
                           elsif (cmp_key = COMPONENT_FINGERPRINTS.keys.detect do |k, _v|
                                    notice.component&.include?(k)
                                  end)
                             COMPONENT_FINGERPRINTS[cmp_key]
                           end
    end
  end
end
