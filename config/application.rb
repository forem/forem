require_relative "boot"

# only require Rails parts that we actually use, this shaves off some memory
# ActiveStorage, ActionCable and TestUnit are not currently used by the app
# see <https://github.com/rails/rails/blob/v5.2.3/railties/lib/rails/all.rb>
%w[
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  sprockets/railtie
].each do |railtie|
  require railtie
end

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
    config.autoload_paths += Dir["#{config.root}/app/facades"]
    config.autoload_paths += Dir["#{config.root}/app/errors"]
    config.autoload_paths += Dir["#{config.root}/lib/"]

    config.active_record.observers = :article_observer, :reaction_observer, :comment_observer
    config.active_job.queue_adapter = :delayed_job

    config.middleware.use Rack::Deflater

    # Globally handle Pundit::NotAuthorizedError by serving 404
    config.action_dispatch.rescue_responses["Pundit::NotAuthorizedError"] = :not_found

    # Rails 5.1 introduced CSRF tokens that change per-form.
    # Unfortunately there isn't an easy way to use them and use view caching at the same time.
    # Therefore we disable "per_form_csrf_tokens" for the time being.
    config.action_controller.per_form_csrf_tokens = false

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
