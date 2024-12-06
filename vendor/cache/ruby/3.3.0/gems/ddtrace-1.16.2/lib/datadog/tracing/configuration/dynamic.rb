# frozen_string_literal: true

require_relative 'dynamic/option'

module Datadog
  module Tracing
    module Configuration
      # Tracing Dynamic Configuration,
      # powered by the Remote Configuration platform.
      module Dynamic
        # Dynamic configuration for `DD_LOGS_INJECTION`.
        class LogInjectionEnabled < SimpleOption
          def initialize
            super('log_injection_enabled', 'DD_LOGS_INJECTION', :log_injection)
          end
        end

        # Dynamic configuration for `DD_TRACE_HEADER_TAGS`.
        class TracingHeaderTags < SimpleOption
          def initialize
            super('tracing_header_tags', 'DD_TRACE_HEADER_TAGS', :header_tags)
          end

          def call(tracing_header_tags)
            # Modify the remote configuration value that it matches the
            # environment variable it configures.
            if tracing_header_tags
              tracing_header_tags.map! do |hash|
                "#{hash['header']}:#{hash['tag_name']}"
              end
            end

            super(tracing_header_tags)
          end
        end

        # Dynamic configuration for `DD_TRACE_SAMPLE_RATE`.
        class TracingSamplingRate < SimpleOption
          def initialize
            super('tracing_sampling_rate', 'DD_TRACE_SAMPLE_RATE', :default_rate)
          end

          # Ensures sampler is rebuilt and new configuration is applied
          def call(tracing_sampling_rate)
            super
            Datadog.send(:components).reconfigure_live_sampler
          end

          protected

          def configuration_object
            Datadog.configuration.tracing.sampling
          end
        end

        # List of all tracing dynamic configuration options supported.
        OPTIONS = [LogInjectionEnabled, TracingHeaderTags, TracingSamplingRate].map do |option_class|
          option = option_class.new
          [option.name, option.env_var, option]
        end
      end
    end
  end
end
