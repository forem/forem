# frozen_string_literal: true

module Datadog
  module CI
    module Ext
      # Defines constants for test tags
      module Test
        CONTEXT_ORIGIN = "ciapp-test"

        TAG_ARGUMENTS = "test.arguments"
        TAG_FRAMEWORK = "test.framework"
        TAG_FRAMEWORK_VERSION = "test.framework_version"
        TAG_NAME = "test.name"
        TAG_SKIP_REASON = "test.skip_reason" # DEV: Not populated yet
        TAG_STATUS = "test.status"
        TAG_SUITE = "test.suite"
        TAG_TRAITS = "test.traits"
        TAG_TYPE = "test.type"

        # Environment runtime tags
        TAG_OS_ARCHITECTURE = "os.architecture"
        TAG_OS_PLATFORM = "os.platform"
        TAG_RUNTIME_NAME = "runtime.name"
        TAG_RUNTIME_VERSION = "runtime.version"

        # TODO: is there a better place for SPAN_KIND?
        TAG_SPAN_KIND = "span.kind"

        module Status
          PASS = "pass"
          FAIL = "fail"
          SKIP = "skip"
        end
      end
    end
  end
end
