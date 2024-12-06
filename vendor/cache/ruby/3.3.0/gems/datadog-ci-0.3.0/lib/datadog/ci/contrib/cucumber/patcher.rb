# frozen_string_literal: true

require "datadog/tracing/contrib/patcher"
require_relative "instrumentation"

module Datadog
  module CI
    module Contrib
      module Cucumber
        # Patcher enables patching of 'cucumber' module.
        module Patcher
          include Datadog::Tracing::Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Cucumber::Runtime.include(Instrumentation)
          end
        end
      end
    end
  end
end
