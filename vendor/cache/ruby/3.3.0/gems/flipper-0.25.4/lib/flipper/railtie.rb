module Flipper
  class Railtie < Rails::Railtie
    config.before_configuration do
      config.flipper = ActiveSupport::OrderedOptions.new.update(
        env_key: "flipper",
        memoize: true,
        preload: true,
        instrumenter: ActiveSupport::Notifications,
        log: true
      )
    end

    initializer "flipper.identifier" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.include Flipper::Identifier
      end
    end

    initializer "flipper.default", before: :load_config_initializers do |app|
      Flipper.configure do |config|
        config.default do
          Flipper.new(config.adapter, instrumenter: app.config.flipper.instrumenter)
        end
      end
    end

    initializer "flipper.log", after: :load_config_initializers do |app|
      flipper = app.config.flipper

      if flipper.log && flipper.instrumenter == ActiveSupport::Notifications
        require "flipper/instrumentation/log_subscriber"
      end
    end

    initializer "flipper.memoizer", after: :load_config_initializers do |app|
      flipper = app.config.flipper

      if flipper.memoize
        app.middleware.use Flipper::Middleware::Memoizer, {
          env_key: flipper.env_key,
          preload: flipper.preload,
          if: flipper.memoize.respond_to?(:call) ? flipper.memoize : nil
        }
      end
    end
  end
end
