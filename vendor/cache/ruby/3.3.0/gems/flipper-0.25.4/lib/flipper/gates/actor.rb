module Flipper
  module Gates
    class Actor < Gate
      # Internal: The name of the gate. Used for instrumentation, etc.
      def name
        :actor
      end

      # Internal: Name converted to value safe for adapter.
      def key
        :actors
      end

      def data_type
        :set
      end

      def enabled?(value)
        !value.empty?
      end

      # Internal: Checks if the gate is open for a thing.
      #
      # Returns true if gate open for thing, false if not.
      def open?(context)
        value = context.values[key]
        if context.thing.nil?
          false
        else
          if protects?(context.thing)
            actor = wrap(context.thing)
            enabled_actor_ids = value
            enabled_actor_ids.include?(actor.value)
          else
            false
          end
        end
      end

      def wrap(thing)
        Types::Actor.wrap(thing)
      end

      def protects?(thing)
        Types::Actor.wrappable?(thing)
      end
    end
  end
end
