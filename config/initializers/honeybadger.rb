# Can be used to implement more programatic error handling
# https://docs.honeybadger.io/lib/ruby/getting-started/ignoring-errors.html#ignore-programmatically

MESSAGE_FINGERPRINTS = {
  "SUSPENDED" => "banned",
  "Rack::Timeout::RequestTimeoutException" => "rack_timeout",
  "Rack::Timeout::RequestTimeoutError" => "rack_timeout",
  "PG::QueryCanceled" => "pg_query_canceled"
}.freeze

COMPONENT_FINGERPRINTS = {
  "internal" => "internal"
}.freeze

Honeybadger.configure do |config|
  config.api_key = ApplicationConfig["HONEYBADGER_API_KEY"]
  config.revision = ApplicationConfig["HEROKU_SLUG_COMMIT"]
  config.exceptions.ignore += [
    Pundit::NotAuthorizedError,
    ActiveRecord::RecordNotFound,
    ActiveRecord::QueryCanceled,
  ]
  config.request.filter_keys += %w[authorization]
  config.sidekiq.attempt_threshold = 10
  config.breadcrumbs.enabled = true

  config.before_notify do |notice|
    notice.fingerprint = if notice.error_message&.include?("SIGTERM") && notice.component&.include?("fetch_all_rss")
                           notice.error_message
                         elsif (msg_key = MESSAGE_FINGERPRINTS.keys.detect { |k, _v| notice.error_message&.include?(k) })
                           MESSAGE_FINGERPRINTS[msg_key]
                         elsif (cmp_key = COMPONENT_FINGERPRINTS.keys.detect { |k, _v| notice.component&.include?(k) })
                           COMPONENT_FINGERPRINTS[cmp_key]
                         end
  end
end
