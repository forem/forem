require 'flipper'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and raises for any writes.
    class ReadOnly
      include ::Flipper::Adapter

      class WriteAttempted < Error
        def initialize(message = nil)
          super(message || 'write attempted while in read only mode')
        end
      end

      # Internal: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(adapter)
        @adapter = adapter
        @name = :read_only
      end

      def features
        @adapter.features
      end

      def get(feature)
        @adapter.get(feature)
      end

      def get_multi(features)
        @adapter.get_multi(features)
      end

      def get_all
        @adapter.get_all
      end

      def add(_feature)
        raise WriteAttempted
      end

      def remove(_feature)
        raise WriteAttempted
      end

      def clear(_feature)
        raise WriteAttempted
      end

      def enable(_feature, _gate, _thing)
        raise WriteAttempted
      end

      def disable(_feature, _gate, _thing)
        raise WriteAttempted
      end
    end
  end
end
