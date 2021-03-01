# rubocop:disable Metrics/BlockLength
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Include middleware to ensure timezone for browser requests for Capybara specs
  # matches the random zonebie timezone set at the beginning of our spec run
  config.middleware.use SetTimeZone

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # See https://github.com/rails/rails/issues/40613#issuecomment-727283155
  config.action_view.cache_template_loading = true

  # NOTE: [Rails 6] this is the default store in testing,
  # as we haven't enabled Rails 6.0 defaults in config/application.rb,
  # we need to keep this explicit, for now
  config.cache_store = :null_store

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory
  # config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Additional setting to make test work. This is possibly useless and can be deleted.
  config.action_mailer.default_url_options = { host: "test.host" }

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.active_job.queue_adapter = :test

  # Debug is the default log_level, but can be changed per environment.
  config.log_level = :debug

  # enable Bullet in testing mode only if requested
  config.after_initialize do
    Bullet.enable = true
    Bullet.raise = true

    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "ApiSecret", association: :user)
    # acts-as-taggable-on has super weird eager loading problems: <https://github.com/mbleigh/acts-as-taggable-on/issues/91>
    Bullet.add_whitelist(type: :n_plus_one_query, class_name: "ActsAsTaggableOn::Tagging", association: :tag)
    # Supress incorrect warnings from Bullet due to included columns: https://github.com/flyerhzm/bullet/issues/147
    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "Article", association: :top_comments)
    Bullet.add_whitelist(type: :unused_eager_loading, class_name: "Comment", association: :user)
    # NOTE: @citizen428 Temporarily ignoring this while working out user - profile relationship
    Bullet.add_whitelist(type: :n_plus_one_query, class_name: "User", association: :profile)
  end
end
# rubocop:enable Metrics/BlockLength

Rails.application.routes.default_url_options = { host: "test.host" }
