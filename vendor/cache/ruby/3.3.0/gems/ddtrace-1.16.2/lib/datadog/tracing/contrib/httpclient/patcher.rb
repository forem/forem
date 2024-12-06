require_relative '../../../core/utils/only_once'
require_relative 'instrumentation'
require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      # Datadog Httpclient integration.
      module Httpclient
        # Patcher enables patching of 'httpclient' module.
        module Patcher
          include Contrib::Patcher

          PATCH_ONLY_ONCE = Core::Utils::OnlyOnce.new

          module_function

          def patched?
            PATCH_ONLY_ONCE.ran?
          end

          def target_version
            Integration.version
          end

          # patch applies our patch
          def patch
            PATCH_ONLY_ONCE.run do
              begin
                ::HTTPClient.include(Instrumentation)
              rescue StandardError => e
                Datadog.logger.error("Unable to apply httpclient integration: #{e}")
              end
            end
          end
        end
      end
    end
  end
end
