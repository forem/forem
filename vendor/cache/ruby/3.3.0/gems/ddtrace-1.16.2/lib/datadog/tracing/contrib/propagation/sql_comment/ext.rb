# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Propagation
        module SqlComment
          module Ext
            ENV_DBM_PROPAGATION_MODE = 'DD_DBM_PROPAGATION_MODE'

            # The default mode for sql comment propagation
            DISABLED = 'disabled'

            # The `service` mode propagates service configuration
            SERVICE = 'service'

            # The `full` mode propagates service configuration + trace context
            FULL = 'full'

            # The value should be `true` when `full` mode
            TAG_DBM_TRACE_INJECTED = '_dd.dbm_trace_injected'

            KEY_DATABASE_SERVICE = 'dddbs'
            KEY_ENVIRONMENT = 'dde'
            KEY_PARENT_SERVICE = 'ddps'
            KEY_VERSION = 'ddpv'
            KEY_TRACEPARENT = 'traceparent'
          end
        end
      end
    end
  end
end
