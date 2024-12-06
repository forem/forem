# frozen_string_literal: true

require_relative "../test_v1"
require_relative "../span"

module Datadog
  module CI
    module TestVisibility
      module Serializers
        module Factories
          # This factory takes care of creating citestcycle serializers when test-level visibility is enabled
          # NOTE: citestcycle is a protocol Datadog uses to submit test execution tracing information to CI visibility
          # backend
          module TestLevel
            module_function

            def serializer(trace, span)
              case span.type
              when Datadog::CI::Ext::AppTypes::TYPE_TEST
                Serializers::TestV1.new(trace, span)
              else
                Serializers::Span.new(trace, span)
              end
            end
          end
        end
      end
    end
  end
end
