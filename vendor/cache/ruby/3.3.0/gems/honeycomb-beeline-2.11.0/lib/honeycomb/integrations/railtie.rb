# frozen_string_literal: true

require "rails/railtie"
require "honeycomb/integrations/rails"

module Honeycomb
  # Automatically capture rack requests and create a trace
  class Railtie < ::Rails::Railtie
    initializer("honeycomb.install_middleware",
                after: :load_config_initializers) do |app|
      if Honeycomb.client
        app.config.middleware.insert_after(
          ActionDispatch::ShowExceptions,
          Honeycomb::Rails::Middleware,
          client: Honeycomb.client,
        )
      end
    end
  end
end
