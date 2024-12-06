# frozen_string_literal: true

require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module Qless
        # Patcher enables patching of 'qless' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require_relative 'qless_job'
            require_relative 'tracer_cleaner'

            # Instrument all Qless Workers
            # These are executed in inverse order of listing here
            ::Qless::Workers::BaseWorker.include(QlessJob)
            ::Qless::Workers::BaseWorker.include(TracerCleaner)
          end

          def get_option(option)
            Datadog.configuration.tracing[:qless].get_option(option)
          end
        end
      end
    end
  end
end
