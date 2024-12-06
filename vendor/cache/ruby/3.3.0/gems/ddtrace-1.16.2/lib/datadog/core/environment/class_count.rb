# frozen_string_literal: true

module Datadog
  module Core
    module Environment
      # Retrieves number of classes from runtime
      module ClassCount
        module_function

        def value
          ::ObjectSpace.count_objects[:T_CLASS]
        end

        def available?
          ::ObjectSpace.respond_to?(:count_objects) \
           && ::ObjectSpace.count_objects.key?(:T_CLASS)
        end
      end
    end
  end
end
