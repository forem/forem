require "active_support/core_ext/integer/time"

# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  # Allow the app to know when booted up in context where we haven't set ENV vars
  # If we have not set this ENV var it means we haven't set the environment
  ENV["ENV_AVAILABLE"] = ENV["APP_DOMAIN"].present?.to_s

  if ENV["ENV_AVAILABLE"] == "false"
    # We still need _something_ here, but if booted without environment (aka asset precompile),
    # it shouldn't need to be the proper value
    ENV["SECRET_KEY_BASE"] = "NOT_SET"
  end
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Attempt to read encrypted secrets from `config/secrets.yml.enc`.
  # Requires an encryption key in `ENV["RAILS_MASTER_KEY"]` or
  # `config/secrets.yml.key`.
  config.read_encrypted_secrets = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {
    "Cache-Control" => "public, s-maxage=#{30.days.to_i}, max-age=#{3000.days.to_i}"
  }

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglify_with_source_maps
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb
  config.assets.digest = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = ENV["FASTLY_CDN_URL"]

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV["FORCE_SSL_IN_RAILS"] == "true"

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV["LOG_LEVEL"] || :error

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  # DEV uses the RedisCloud Heroku Add-On which comes with the predefined env variable REDISCLOUD_URL
  redis_url = ENV["REDISCLOUD_URL"]
  redis_url ||= ENV["REDIS_URL"]
  default_expiration = 24.hours.to_i
  config.cache_store = :redis_cache_store, { url: redis_url, expires_in: default_expiration }

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "practical_developer_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Log disallowed deprecations.
  config.active_support.disallowed_deprecation = :log

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Filter sensitive information from production logs
  config.filter_parameters += %i[
    auth_data_dump content email encrypted
    encrypted_password message_html message_markdown
    password previous_refresh_token refresh_token secret
    to token current_sign_in_ip last_sign_in_ip
    reset_password_token remember_token unconfirmed_email
  ]

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    # Use a different logger for distributed setups.
    # require 'syslog/logger'
    # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  protocol = ENV["APP_PROTOCOL"] || "http://"

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: protocol + ENV["APP_DOMAIN"].to_s }
  ActionMailer::Base.smtp_settings = if ENV["SENDGRID_API_KEY"].present?
                                       {
                                         address: "smtp.sendgrid.net",
                                         port: 587,
                                         authentication: :plain,
                                         user_name: "apikey",
                                         password: ENV["SENDGRID_API_KEY"],
                                         domain: ENV["APP_DOMAIN"]
                                       }
                                     else
                                       {
                                         address: ENV["SMTP_ADDRESS"],
                                         port: ENV["SMTP_PORT"],
                                         authentication: ENV["SMTP_AUTHENTICATION"],
                                         user_name: ENV["SMTP_USER_NAME"],
                                         password: ENV["SMTP_PASSWORD"],
                                         domain: ENV["SMTP_DOMAIN"]
                                       }
                                     end

  if ENV["HEROKU_APP_URL"].present? && ENV["HEROKU_APP_URL"] != ENV["APP_DOMAIN"]
    config.middleware.use Rack::HostRedirect,
                          ENV["HEROKU_APP_URL"] => ENV["APP_DOMAIN"]
  end

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
# rubocop:enable Metrics/BlockLength

Rails.application.routes.default_url_options = {
  protocol: (ENV["APP_PROTOCOL"] || "http://").delete_suffix("://")
}
