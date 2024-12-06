require_relative '../integration'
require_relative 'configuration/settings'
require_relative 'patcher'

module Datadog
  module Tracing
    module Contrib
      module Qless
        # Description of Qless integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('0.10.0')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :qless, auto_patch: true

          def self.version
            Gem.loaded_specs['qless'] && Gem.loaded_specs['qless'].version
          end

          def self.loaded?
            !defined?(::Qless).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
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
