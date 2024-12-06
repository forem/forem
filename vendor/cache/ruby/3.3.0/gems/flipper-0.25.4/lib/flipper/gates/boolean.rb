module Flipper
  module Gates
    class Boolean < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :boolean
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :boolean
      end

      def data_type
        :boolean
      end

      def enabled?(value)
        !!value
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if explicitly set to true, false if explicitly set to false
      # or nil if not explicitly set.
      def open?(context)
        context.values[key]
      end

      def wrap(thing)
        Types::Boolean.wrap(thing)
      end

      def protects?(thing)
        case thing
        when Types::Boolean, TrueClass, FalseClass
          true
        else
          false
        end
      end
    end
  end
end
