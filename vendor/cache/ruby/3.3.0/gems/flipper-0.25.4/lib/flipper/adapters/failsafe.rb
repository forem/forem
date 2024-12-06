module Flipper
  module Adapters
    class Failsafe
      include ::Flipper::Adapter

      # Public: The name of the adapter.
      attr_reader :name

      # Public: Build a new Failsafe instance.
      #
      # adapter   - Flipper adapter to guard.
      # options   - Hash of options:
      #             :errors - Array of exception types for which to fail safe

      def initialize(adapter, options = {})
        @adapter = adapter
        @errors = options.fetch(:errors, [StandardError])
        @name = :failsafe
      end

      def features
        @adapter.features
      rescue *@errors
        Set.new
      end

      def add(feature)
        @adapter.add(feature)
      rescue *@errors
        false
      end

      def remove(feature)
        @adapter.remove(feature)
      rescue *@errors
        false
      end

      def clear(feature)
        @adapter.clear(feature)
      rescue *@errors
        false
      end

      def get(feature)
        @adapter.get(feature)
      rescue *@errors
        {}
      end

      def get_multi(features)
        @adapter.get_multi(features)
      rescue *@errors
        {}
      end

      def get_all
        @adapter.get_all
      rescue *@errors
        {}
      end

      def enable(feature, gate, thing)
        @adapter.enable(feature, gate, thing)
      rescue *@errors
        false
      end

      def disable(feature, gate, thing)
        @adapter.disable(feature, gate, thing)
      rescue *@errors
        false
      end
    end
  end
end
