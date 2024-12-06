require_relative '../../core/utils/only_once'
require_relative '../ext/forking'

module Datadog
  module Profiling
    module Tasks
      # Takes care of loading our extensions/monkey patches to handle fork() and validating if CPU-time profiling is usable
      class Setup
        ACTIVATE_EXTENSIONS_ONLY_ONCE = Core::Utils::OnlyOnce.new

        def run
          ACTIVATE_EXTENSIONS_ONLY_ONCE.run do
            begin
              activate_forking_extensions
              setup_at_fork_hooks
            rescue StandardError, ScriptError => e
              Datadog.logger.warn do
                "Profiler extensions unavailable. Cause: #{e.class.name} #{e.message} " \
                "Location: #{Array(e.backtrace).first}"
              end
            end
          end
        end

        private

        def activate_forking_extensions
          if Ext::Forking.supported?
            Ext::Forking.apply!
          elsif Datadog.configuration.profiling.enabled
            Datadog.logger.debug('Profiler forking extensions skipped; forking not supported.')
          end
        rescue StandardError, ScriptError => e
          Datadog.logger.warn do
            "Profiler forking extensions unavailable. Cause: #{e.class.name} #{e.message} " \
            "Location: #{Array(e.backtrace).first}"
          end
        end

        def setup_at_fork_hooks
          if Process.respond_to?(:at_fork)
            Process.at_fork(:child) do
              begin
                # Restart profiler, if enabled
                Profiling.start_if_enabled
              rescue StandardError => e
                Datadog.logger.warn do
                  "Error during post-fork hooks. Cause: #{e.class.name} #{e.message} " \
                  "Location: #{Array(e.backtrace).first}"
                end
              end
            end
          end
        end
      end
    end
  end
end
