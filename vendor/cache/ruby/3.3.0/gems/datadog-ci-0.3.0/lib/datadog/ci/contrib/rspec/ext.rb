# frozen_string_literal: true

module Datadog
  module CI
    module Contrib
      module RSpec
        # RSpec integration constants
        # TODO: mark as `@public_api` when GA, to protect from resource and tag name changes.
        module Ext
          APP = "rspec"
          ENV_ENABLED = "DD_TRACE_RSPEC_ENABLED"
          ENV_OPERATION_NAME = "DD_TRACE_RSPEC_OPERATION_NAME"
          FRAMEWORK = "rspec"
          OPERATION_NAME = "rspec.example"
          SERVICE_NAME = "rspec"
          TEST_TYPE = "test"
        end
      end
    end
  end
end
