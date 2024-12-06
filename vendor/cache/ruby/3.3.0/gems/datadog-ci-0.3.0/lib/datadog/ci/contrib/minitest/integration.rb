# frozen_string_literal: true

require_relative "../integration"
require_relative "configuration/settings"
require_relative "patcher"

module Datadog
  module CI
    module Contrib
      module Minitest
        # Description of Minitest integration
        class Integration
          include Datadog::CI::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new("5.0.0")

          register_as :minitest

          def self.version
            Gem.loaded_specs["minitest"] && Gem.loaded_specs["minitest"].version
          end

          def self.loaded?
            !defined?(::Minitest).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          # test environments should not auto instrument test libraries
          def auto_instrument?
            false
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            Patcher
          end
        end
      end
    end
  end
end
