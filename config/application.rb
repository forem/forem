require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PracticalDeveloper
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.autoload_paths += Dir["#{config.root}/app/labor/"]
    config.autoload_paths += Dir["#{config.root}/app/decorators/"]
    config.autoload_paths += Dir["#{config.root}/app/services/"]
    config.autoload_paths += Dir["#{config.root}/app/liquid_tags/"]
    config.autoload_paths += Dir["#{config.root}/app/black_box/"]
    config.autoload_paths += Dir["#{config.root}/app/sanitizers"]
    config.autoload_paths += Dir["#{config.root}/app/facades"]
    config.autoload_paths += Dir["#{config.root}/app/errors"]
    config.autoload_paths += Dir["#{config.root}/app/view_objects"]
    config.autoload_paths += Dir["#{config.root}/lib/"]

    config.active_job.queue_adapter = :sidekiq

    config.middleware.use Rack::Deflater

    # Globally handle Pundit::NotAuthorizedError by serving 404
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :not_found

    # Rails 5.1 introduced CSRF tokens that change per-form.
    # Unfortunately there isn't an easy way to use them and use view caching at the same time.
    # Therefore we disable "per_form_csrf_tokens" for the time being.
    config.action_controller.per_form_csrf_tokens = false

    # Enable CORS for API v0
    # (logging is only activated when debug is enabled)
    debug_cors = ENV["DEBUG_CORS"].present? ? true : false
    config.middleware.insert_before 0, Rack::Cors, debug: debug_cors, logger: (-> { Rails.logger }) do
      allow do
        origins do |source, _env|
          source # echo back the client's `Origin` header instead of using `*`
        end

        # allowed public APIs
        %w[articles comments listings podcast_episodes tags users videos].each do |resource_name|
          # allow read operations, disallow custom headers (eg. api-key) and enable preflight caching
          # NOTE: Chrome caps preflight caching at 2 hours, Firefox at 24 hours
          # see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age#Directives
          resource "/api/#{resource_name}/*", methods: %i[head get options], headers: [], max_age: 2.hours.to_i
        end
      end
    end

    # After-initialize checker to add routes to reserved words
    config.after_initialize do
      Rails.application.reload_routes!
      top_routes = []
      Rails.application.routes.routes.each do |route|
        route = route.path.spec.to_s
        unless route.starts_with?("/:")
          route = route.split("/")[1]
          route = route.split("(")[0] if route&.include?("(")
          top_routes << route
        end
      end
      ReservedWords.all = [ReservedWords::BASE_WORDS + top_routes].flatten.compact.uniq
    end
  end
end
