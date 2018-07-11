require_relative 'boot'

require 'rails/all'

require "action_view/railtie"
require "sprockets/railtie"
require 'sprockets/es6'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PracticalDeveloper
  class Application < Rails::Application
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += Dir["#{config.root}/app/labor/"]
    config.autoload_paths += Dir["#{config.root}/app/decorators/"]
    config.autoload_paths += Dir["#{config.root}/app/services/"]
    config.autoload_paths += Dir["#{config.root}/app/liquid_tags/"]
    config.autoload_paths += Dir["#{config.root}/app/observers/"]
    config.autoload_paths += Dir["#{config.root}/app/black_box/"]
    config.autoload_paths += Dir["#{config.root}/app/sanitizers"]
    config.autoload_paths += Dir["#{config.root}/lib/"]

    config.active_record.observers = :article_observer, :reaction_observer
    config.active_job.queue_adapter = :delayed_job

    config.middleware.use Rack::Deflater

    # Replace with a lambda or method name defined in ApplicationController
    # to implement access control for the Flipflop dashboard.
    config.flipflop.dashboard_access_filter = -> { head :forbidden unless current_user.has_any_role?(:super_admin) }

    # Globally handle Pundit::NotAuthorizedError by serving 404
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :not_found

    # After-initialize checker to add routes to reserved words
    config.after_initialize do
      Rails.application.reload_routes!
      top_routes = []
      Rails.application.routes.routes.each do |route|
        route = route.path.spec.to_s
        unless route.starts_with?('/:')
          route = route.split('/')[1]
          route = route.split('(')[0] if route && route.include?('(')
          top_routes << route
        end
      end
      ReservedWords.all = [ReservedWords::BASE_WORDS + top_routes].flatten.compact.uniq
    end
  end
end
