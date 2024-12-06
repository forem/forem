# frozen_string_literal: true

require 'date'
require 'json'
require 'rbconfig'
require_relative '../../core/diagnostics/environment_logger'

module Datadog
  module Profiling
    module Diagnostics
      # Collects and logs Profiling diagnostic information
      module EnvironmentLogger
        extend Core::Diagnostics::EnvironmentLogging

        def self.collect_and_log!
          log_once! do
            data = EnvironmentCollector.collect_config!
            log_configuration!('PROFILING', data.to_json)
          end
        rescue => e
          logger.warn("Failed to collect profiling environment information: #{e} Location: #{Array(e.backtrace).first}")
        end
      end

      # Collects environment information for Profiling diagnostic logging
      module EnvironmentCollector
        def self.collect_config!(*args)
          {
            profiling_enabled: profiling_enabled
          }
        end

        def self.profiling_enabled
          !!Datadog.configuration.profiling.enabled
        end
      end
    end
  end
end
