# frozen_string_literal: true

module Datadog
  module CI
    module Contrib
      module Minitest
        # Minitest integration constants
        # TODO: mark as `@public_api` when GA, to protect from resource and tag name changes.
        module Ext
          APP = "minitest"
          ENV_ENABLED = "DD_TRACE_MINITEST_ENABLED"
          ENV_OPERATION_NAME = "DD_TRACE_MINITEST_OPERATION_NAME"
          FRAMEWORK = "minitest"
          OPERATION_NAME = "minitest.test"
          SERVICE_NAME = "minitest"
          TEST_TYPE = "test"
        end
      end
    end
  end
end
