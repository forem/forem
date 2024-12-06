require_relative 'configuration/settings'
require_relative 'patcher'
require_relative '../integration'
require_relative '../rails/utils'

module Datadog
  module Tracing
    module Contrib
      module ActionPack
        # Describes the ActionPack integration
        class Integration
          include Contrib::Integration

          MINIMUM_VERSION = Gem::Version.new('3.2')

          # @public_api Changing the integration name or integration options can cause breaking changes
          register_as :action_pack, auto_patch: false

          def self.version
            Gem.loaded_specs['actionpack'] && Gem.loaded_specs['actionpack'].version
          end

          def self.loaded?
            !defined?(::ActionPack).nil?
          end

          def self.compatible?
            super && version >= MINIMUM_VERSION
          end

          # enabled by rails integration so should only auto instrument
          # if detected that it is being used without rails
          def auto_instrument?
            !Contrib::Rails::Utils.railtie_supported?
          end

          def new_configuration
            Configuration::Settings.new
          end

          def patcher
            ActionPack::Patcher
          end
        end
      end
    end
  end
end
