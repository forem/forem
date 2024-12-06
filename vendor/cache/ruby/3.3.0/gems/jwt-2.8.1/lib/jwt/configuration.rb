# frozen_string_literal: true

require_relative 'configuration/container'

module JWT
  module Configuration
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= ::JWT::Configuration::Container.new
    end
  end
end
