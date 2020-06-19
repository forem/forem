require "rails"
require "timber-rails/railtie"

# Defualt the rails logger to nothing, each test shoould be
# responsible for setting up the logger
logger = Timber::Logger.new(nil) # change to STDOUT to see rails logs
Rails.logger = logger

class RailsApp < Rails::Application
  if ::Rails.version =~ /^3\./
    config.secret_token = '1e05af2b349457936a41427e63450937'
  else
    config.secret_key_base = '1e05af2b349457936a41427e63450937'
  end

  # This ensures our tests fail, otherwise exceptions get swallowed by ActionDispatch::DebugExceptions
  config.action_dispatch.show_exceptions = false
  config.active_support.deprecation = :stderr
  config.eager_load = false
end

RailsApp.initialize!

module Support
  module Rails
    def dispatch_rails_request(path, additional_env_options = {})
      application = ::Rails.application
      env = application.respond_to?(:env_config) ? application.env_config.clone : application.env_defaults.clone
      env["rack.request.cookie_hash"] = {}.with_indifferent_access
      env["CONTENT_LENGTH"] = 100
      env["REMOTE_ADDR"] = "123.456.789.10"
      env["HTTP_X_REQUEST_ID"] = "unique-request-id-1234"
      env["action_dispatch.request_id"] = env["HTTP_X_REQUEST_ID"]
      env = env.merge(additional_env_options)
      ::Rack::MockRequest.new(application).get(path, env)
    end

    def with_rails_logger(logger)
      old_logger = ::Rails.logger

      # We have to set these again because rails set's these after initialization.
      # Since we've already booted the rails app we need to update them all as we
      # change the logger.
      #
      # You can see here that they use simple class attribute, hence the reason we need
      # to update all of them: https://github.com/rails/rails/blob/700ec897f97c60016ad748236bf3a49ef15a20de/actionview/lib/action_view/base.rb#L157
      ::ActionCable::Server::Base.logger = logger if defined?(::ActionCable::Server::Base) && ::ActionCable::Server::Base.respond_to?(:logger=)
      ::ActionController::Base.logger = logger if defined?(::ActionController::Base) && ::ActionController::Base.respond_to?(:logger=)
      ::ActionMailer::Base.logger = logger if defined?(::ActionMailer::Base) && ::ActionMailer::Base.respond_to?(:logger=)
      ::ActionView::Base.logger = logger if defined?(::ActionView::Base) && ::ActionView::Base.respond_to?(:logger=)
      ::ActiveRecord::Base.logger = logger if defined?(::ActiveRecord::Base) && ::ActiveRecord::Base.respond_to?(:logger=)
      ::Rails.logger = logger

      yield

      ::Rails.logger = old_logger
    end
  end
end

# This is necessary as tests use Timber::Config.send(:new) to create
# an instance of the Config class instead of the Timber::Config
# singleton.
module Timber
  class Config
    def logrageify!
      integrations.action_controller.silence = true
      integrations.action_view.silence = true
      integrations.active_record.silence = true
      integrations.rack.http_events.collapse_into_single_event = true
    end
  end
end

RSpec.configure do |config|
  config.include Support::Rails
end
