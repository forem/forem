# frozen_string_literal: true

require_relative "../ext"
require_relative "../../settings"

module Datadog
  module CI
    module Contrib
      module RSpec
        module Configuration
          # Custom settings for the RSpec integration
          # TODO: mark as `@public_api` when GA
          class Settings < Datadog::CI::Contrib::Settings
            option :enabled do |o|
              o.type :bool
              o.env Ext::ENV_ENABLED
              o.default true
            end

            option :service_name do |o|
              o.type :string
              o.default { Datadog.configuration.service_without_fallback || Ext::SERVICE_NAME }
            end

            option :operation_name do |o|
              o.type :string
              o.env Ext::ENV_OPERATION_NAME
              o.default Ext::OPERATION_NAME
            end
          end
        end
      end
    end
  end
end
