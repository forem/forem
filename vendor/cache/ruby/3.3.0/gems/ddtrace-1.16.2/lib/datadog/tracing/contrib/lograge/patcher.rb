# frozen_string_literal: true

require_relative '../patcher'
require_relative 'instrumentation'

module Datadog
  module Tracing
    module Contrib
      # Datadog Lograge integration.
      module Lograge
        # Patcher enables patching of 'lograge' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          # patch applies our patch
          def patch
            ::Lograge::LogSubscribers::Base.include(Instrumentation)
          end
        end
      end
    end
  end
end
