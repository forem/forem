require "active_support/core_ext/integer/time"

# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"], expires_in: 1.hour.to_i }

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Allows setting a warning threshold for query result size.
  # If the number of records returned by a query exceeds the threshold, a warning is logged.
  # This can be used to identify queries which might be causing a memory bloat.
  config.active_record.warn_on_records_fetched_greater_than = 1500

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  config.action_view.annotate_rendered_view_with_filenames = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.hosts << ENV["APP_DOMAIN"] unless ENV["APP_DOMAIN"].nil?
  if (gitpod_workspace_url = ENV["GITPOD_WORKSPACE_URL"])
    config.hosts << /.*#{URI.parse(gitpod_workspace_url).host}/
  end
  config.app_domain = ENV["APP_DOMAIN"] || "localhost:3000"

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: config.app_domain }
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV["SMTP_PORT"],
    authentication: ENV["SMTP_AUTHENTICATION"].presence || :plain,
    user_name: ENV["SMTP_USER_NAME"],
    password: ENV["SMTP_PASSWORD"],
    domain: ENV["SMTP_DOMAIN"].presence || config.app_domain
  }

  config.action_mailer.preview_path = Rails.root.join("spec/mailers/previews")

  config.public_file_server.enabled = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Debug is the default log_level, but can be changed per environment.
  config.log_level = :debug

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.after_initialize do
    # See <https://github.com/flyerhzm/bullet#configuration> for other Bullet config options
    Bullet.enable = true

    Bullet.add_footer = true
    Bullet.console = true
    Bullet.rails_logger = true

    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "ApiSecret", association: :user)
    # acts-as-taggable-on has super weird eager loading problems: <https://github.com/mbleigh/acts-as-taggable-on/issues/91>
    Bullet.add_whitelist(type: :n_plus_one_query, class_name: "ActsAsTaggableOn::Tagging", association: :tag)
    # Supress incorrect warnings from Bullet due to included columns: https://github.com/flyerhzm/bullet/issues/147
    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "Article", association: :top_comments)
    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "Comment", association: :user)
    # NOTE: @citizen428 Temporarily ignoring this while working out user - profile relationship
    Bullet.add_whitelist(type: :n_plus_one_query, class_name: "User", association: :profile)

    # Check if there are any data update scripts to run during startup
    if %w[Console Server DBConsole].any? { |const| Rails.const_defined?(const) } && DataUpdateScript.scripts_to_run?
      message = "Data update scripts need to be run before you can start the application. " \
        "Please run 'rails data_updates:run'"
      raise message
    end
  end
end

Rails.application.routes.default_url_options = { host: Rails.application.config.app_domain }
# rubocop:enable Metrics/BlockLength
