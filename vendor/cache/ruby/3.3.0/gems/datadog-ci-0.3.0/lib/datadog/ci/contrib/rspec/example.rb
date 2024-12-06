# frozen_string_literal: true

require_relative "../../recorder"
require_relative "../../ext/test"
require_relative "ext"

module Datadog
  module CI
    module Contrib
      module RSpec
        # Instrument RSpec::Core::Example
        module Example
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # Instance methods for configuration
          module InstanceMethods
            def run(example_group_instance, reporter)
              return super unless configuration[:enabled]

              test_name = full_description.strip
              if metadata[:description].empty?
                # for unnamed it blocks this appends something like "example at ./spec/some_spec.rb:10"
                test_name += " #{description}"
              end

              CI::Recorder.trace(
                configuration[:operation_name],
                {
                  span_options: {
                    resource: test_name,
                    service: configuration[:service_name]
                  },
                  framework: Ext::FRAMEWORK,
                  framework_version: CI::Contrib::RSpec::Integration.version.to_s,
                  test_name: test_name,
                  test_suite: metadata[:example_group][:file_path],
                  test_type: Ext::TEST_TYPE
                }
              ) do |span|
                result = super

                case execution_result.status
                when :passed
                  CI::Recorder.passed!(span)
                when :failed
                  CI::Recorder.failed!(span, execution_result.exception)
                else
                  CI::Recorder.skipped!(span, execution_result.exception) if execution_result.example_skipped?
                end

                result
              end
            end

            private

            def configuration
              Datadog.configuration.ci[:rspec]
            end
          end
        end
      end
    end
  end
end
