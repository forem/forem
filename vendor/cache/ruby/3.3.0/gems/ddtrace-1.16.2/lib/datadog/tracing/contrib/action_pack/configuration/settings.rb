require_relative '../../configuration/settings'
require_relative '../ext'

require_relative '../../../../core'

module Datadog
  module Tracing
    module Contrib
      module ActionPack
        module Configuration
          # Custom settings for the ActionPack integration
          # @public_api
          class Settings < Contrib::Configuration::Settings
            option :enabled do |o|
              o.type :bool
              o.env Ext::ENV_ENABLED
              o.default true
            end

            option :analytics_enabled do |o|
              o.type :bool, nilable: true
              o.env Ext::ENV_ANALYTICS_ENABLED
            end

            option :analytics_sample_rate do |o|
              o.type :float
              o.env Ext::ENV_ANALYTICS_SAMPLE_RATE
              o.default 1.0
            end

            # DEV-2.0: Breaking changes for removal.
            option :exception_controller do |o|
              o.after_set do |value|
                if value
                  Datadog::Core.log_deprecation do
                    'The error controller is now automatically detected. '\
                    "Option `#{o.instance_variable_get(:@name)}` is no longer required and will be removed."
                  end
                end
              end
            end

            option :service_name
          end
        end
      end
    end
  end
end
