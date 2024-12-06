# frozen_string_literal: true

require_relative "../../recorder"
require_relative "../../ext/test"
require_relative "ext"

module Datadog
  module CI
    module Contrib
      module Cucumber
        # Defines collection of instrumented Cucumber events
        class Formatter
          attr_reader :config, :current_feature_span, :current_step_span
          private :config
          private :current_feature_span, :current_step_span

          def initialize(config)
            @config = config

            bind_events(config)
          end

          def bind_events(config)
            config.on_event :test_case_started, &method(:on_test_case_started)
            config.on_event :test_case_finished, &method(:on_test_case_finished)
            config.on_event :test_step_started, &method(:on_test_step_started)
            config.on_event :test_step_finished, &method(:on_test_step_finished)
          end

          def on_test_case_started(event)
            @current_feature_span = CI::Recorder.trace(
              configuration[:operation_name],
              {
                span_options: {
                  resource: event.test_case.name,
                  service: configuration[:service_name]
                },
                framework: Ext::FRAMEWORK,
                framework_version: CI::Contrib::Cucumber::Integration.version.to_s,
                test_name: event.test_case.name,
                test_suite: event.test_case.location.file,
                test_type: Ext::TEST_TYPE
              }
            )
          end

          def on_test_case_finished(event)
            return if @current_feature_span.nil?

            if event.result.skipped?
              CI::Recorder.skipped!(@current_feature_span)
            elsif event.result.ok?
              CI::Recorder.passed!(@current_feature_span)
            elsif event.result.failed?
              CI::Recorder.failed!(@current_feature_span)
            end

            @current_feature_span.finish
          end

          def on_test_step_started(event)
            trace_options = {
              resource: event.test_step.to_s,
              span_type: Ext::STEP_SPAN_TYPE
            }
            @current_step_span = Tracing.trace(Ext::STEP_SPAN_TYPE, **trace_options)
          end

          def on_test_step_finished(event)
            return if @current_step_span.nil?

            if event.result.skipped?
              CI::Recorder.skipped!(@current_step_span, event.result.exception)
            elsif event.result.ok?
              CI::Recorder.passed!(@current_step_span)
            elsif event.result.failed?
              CI::Recorder.failed!(@current_step_span, event.result.exception)
            end

            @current_step_span.finish
          end

          private

          def configuration
            Datadog.configuration.ci[:cucumber]
          end
        end
      end
    end
  end
end
