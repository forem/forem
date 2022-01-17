require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Dotenv::Railtie.load if Rails.env.test? || Rails.env.development?

module PracticalDeveloper
  class Application < Rails::Application
    # Specify the default Rails settings version we're targetting
    # See: https://guides.rubyonrails.org/configuring.html#results-of-config-load-defaults
    config.load_defaults 6.0

    ### FRAMEWORK DEFAULT OVERRIDES
    # Override new framework defaults to keep existing behavior.
    #
    # NOTE: For booleans the new default is the opposite of what we're setting here. For other
    # options, the new default is mentioned in a comment. Once we're ready to enable a new default
    # setting we can remove the line here.

    ## Rails 5.0
    # There is no easy way to use per-form tokens and view caching at the same time.
    # Therefore we disable "per_form_csrf_tokens" for the time being.
    config.action_controller.per_form_csrf_tokens = false

    ## Rails 6.1
    # This replaces the old config.active_support.use_sha1_digests from Rails 5.2
    config.active_support.hash_digest_class = ::Digest::MD5 # New default is ::Digest::SHA1
    ### END FRAMEWORK DEFAULT OVERIDES

    # Disable auto adding of default load paths to $LOAD_PATH
    # Setting this to false saves Ruby from checking these directories when
    # resolving require calls with relative paths, and saves Bootsnap work and
    # RAM, since it does not need to build an index for them.
    # see https://github.com/rails/rails/blob/6-0-stable/railties/CHANGELOG.md#rails-600rc2-july-22-2019
    config.add_autoload_paths_to_load_path = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.autoload_paths += Dir["#{config.root}/lib"]
    config.eager_load_paths += Dir["#{config.root}/lib"]

    config.middleware.use Rack::Deflater

    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]

    config.i18n.fallbacks = [:en]

    # Globally handle Pundit::NotAuthorizedError by serving 404
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :not_found

    # After-initialize checker to add routes to reserved words
    config.after_initialize do
      # Add routes to reserved words
      Rails.application.reload_routes!
      top_routes = []
      Rails.application.routes.routes.each do |route|
        route = route.path.spec.to_s
        next if route.starts_with?("/:")

        route = route.split("/")[1]
        route = route.split("(")[0] if route&.include?("(")
        top_routes << route
      end
      ReservedWords.all = [ReservedWords::BASE_WORDS + top_routes].flatten.compact.uniq
    end
  end
end
