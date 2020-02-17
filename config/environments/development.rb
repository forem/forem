Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  # As the integrity check is currently broken under Docker with webpacker,
  # we can't enable this flag by default
  # see <https://github.com/thepracticaldev/dev.to/pull/296#discussion_r210635685>
  config.webpacker.check_yarn_integrity = ENV.fetch("YARN_INTEGRITY_ENABLED", "true") == "true"

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

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

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  config.action_mailer.perform_caching = false

  config.app_domain = "localhost:3000"

  config.action_mailer.default_url_options = { host: "localhost:3000" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: config.app_domain }
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: "587",
    enable_starttls_auto: true,
    user_name: '<%= ENV["DEVELOPMENT_EMAIL_USERNAME"] %>',
    password: '<%= ENV["DEVELOPMENT_EMAIL_PASSWORD"] %>',
    authentication: :plain,
    domain: "localhost:3000"
  }

  config.action_mailer.preview_path = Rails.root.join("spec/mailers/previews")

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.public_file_server.enabled = true

  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Debug is the default log_level, but can be changed per environment.
  config.log_level = :debug

  # See <https://github.com/flyerhzm/bullet#configuration> for other config options
  config.after_initialize do
    Bullet.enable = true

    Bullet.add_footer = true
    Bullet.console = true
    Bullet.rails_logger = true

    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "ApiSecret", association: :user)
    # acts-as-taggable-on has super weird eager loading problems: <https://github.com/mbleigh/acts-as-taggable-on/issues/91>
    Bullet.add_whitelist(type: :n_plus_one_query, class_name: "ActsAsTaggableOn::Tagging", association: :tag)

    DATA_UPDATE_CHECK_COMMANDS = %w[c console s server].freeze
    if DATA_UPDATE_CHECK_COMMANDS.include?(ENV["COMMAND"])
      script_ids = DataUpdateScript.load_script_ids
      scripts_to_run = DataUpdateScript.where(id: script_ids).select(&:enqueued?)
      if scripts_to_run.any?
        raise "Data update scripts need to be run before you can start the application. Please run rake data_updates:run"
      end
    end
  end

  # Docker specific development configuration
  if File.file?("/.dockerenv")
    # Using shell tools so we don't need to require Socket and IPAddr
    host_ip = `/sbin/ip route|awk '/default/ { print $3 }'`.strip
    logger = Logger.new(STDOUT)
    logger.info "Whitelisting #{host_ip} for BetterErrors and Web Console"

    if defined?(BetterErrors::Middleware)
      BetterErrors::Middleware.allow_ip!(host_ip)
    end
    config.web_console.whitelisted_ips << host_ip
  end
end

Rails.application.routes.default_url_options = { host: Rails.application.config.app_domain }
