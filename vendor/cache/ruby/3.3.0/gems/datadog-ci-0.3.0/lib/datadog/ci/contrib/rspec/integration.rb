# frozen_string_literal: true

require_relative "../integration"
require_relative "configuration/settings"
require_relative "patcher"

module Datadog
  module CI
    module Contrib
      module RSpec
        # Description of RSpec integration
        class Integration
          include Datadog::CI::Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new("3.0.0")

          register_as :rspec

          def self.version
            Gem.loaded_specs["rspec-core"] \
              && Gem.loaded_specs["rspec-core"].version
          end

          def self.loaded?
            !defined?(::RSpec).nil? && !defined?(::RSpec::Core).nil? && \
              !defined?(::RSpec::Core::Example).nil?
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
