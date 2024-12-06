# frozen_string_literal: true

require_relative "hooks"

module Datadog
  module CI
    module Contrib
      module Minitest
        # Patcher enables patching of 'minitest' module.
        module Patcher
          include Datadog::Tracing::Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            ::Minitest::Test.include(Hooks)
          end
        end
      end
    end
  end
end
