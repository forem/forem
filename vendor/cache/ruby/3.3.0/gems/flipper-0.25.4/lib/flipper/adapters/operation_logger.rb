require 'delegate'

module Flipper
  module Adapters
    # Public: Adapter that wraps another adapter and stores the operations.
    #
    # Useful in tests to verify calls and such. Never use outside of testing.
    class OperationLogger < SimpleDelegator
      include ::Flipper::Adapter

      class Operation
        attr_reader :type, :args

        def initialize(type, args)
          @type = type
          @args = args
        end
      end

      OperationTypes = [
        :features,
        :add,
        :remove,
        :clear,
        :get,
        :get_multi,
        :get_all,
        :enable,
        :disable,
      ].freeze

      # Internal: An array of the operations that have happened.
      attr_reader :operations

      # Internal: The name of the adapter.
      attr_reader :name

      # Public
      def initialize(adapter, operations = nil)
        super(adapter)
        @adapter = adapter
        @name = :operation_logger
        @operations = operations || []
      end

      # Public: The set of known features.
      def features
        @operations << Operation.new(:features, [])
        @adapter.features
      end

      # Public: Adds a feature to the set of known features.
      def add(feature)
        @operations << Operation.new(:add, [feature])
        @adapter.add(feature)
      end

      # Public: Removes a feature from the set of known features and clears
      # all the values for the feature.
      def remove(feature)
        @operations << Operation.new(:remove, [feature])
        @adapter.remove(feature)
      end

      # Public: Clears all the gate values for a feature.
      def clear(feature)
        @operations << Operation.new(:clear, [feature])
        @adapter.clear(feature)
      end

      # Public
      def get(feature)
        @operations << Operation.new(:get, [feature])
        @adapter.get(feature)
      end

      # Public
      def get_multi(features)
        @operations << Operation.new(:get_multi, [features])
        @adapter.get_multi(features)
      end

      # Public
      def get_all
        @operations << Operation.new(:get_all, [])
        @adapter.get_all
      end

      # Public
      def enable(feature, gate, thing)
        @operations << Operation.new(:enable, [feature, gate, thing])
        @adapter.enable(feature, gate, thing)
      end

      # Public
      def disable(feature, gate, thing)
        @operations << Operation.new(:disable, [feature, gate, thing])
        @adapter.disable(feature, gate, thing)
      end

      # Public: Count the number of times a certain operation happened.
      def count(type)
        type(type).size
      end

      # Public: Get all operations of a certain type.
      def type(type)
        @operations.select { |operation| operation.type == type }
      end

      # Public: Get the last operation of a certain type.
      def last(type)
        @operations.reverse.find { |operation| operation.type == type }
      end

      # Public: Resets the operation log to empty
      def reset
        @operations.clear
      end

      def inspect
        inspect_id = ::Kernel::format "%x", (object_id * 2)
        %(#<#{self.class}:0x#{inspect_id} @name=#{name.inspect}, @operations=#{@operations.inspect}, @adapter=#{@adapter.inspect}>)
      end
    end
  end
end
