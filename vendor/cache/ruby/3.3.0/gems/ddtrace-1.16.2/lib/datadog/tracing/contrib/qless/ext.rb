# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Qless
        # Qless integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_QLESS_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_QLESS_ANALYTICS_SAMPLE_RATE'
          ENV_TAG_JOB_DATA = 'DD_QLESS_TAG_JOB_DATA'
          ENV_TAG_JOB_TAGS = 'DD_QLESS_TAG_JOB_TAGS'
          SERVICE_NAME = 'qless'
          SPAN_JOB = 'qless.job'
          TAG_JOB_ID = 'qless.job.id'
          TAG_JOB_DATA = 'qless.job.data'
          TAG_JOB_QUEUE = 'qless.job.queue'
          TAG_JOB_TAGS = 'qless.job.tags'
          TAG_COMPONENT = 'qless'
          TAG_OPERATION_JOB = 'job'
        end
      end
    end
  end
end
