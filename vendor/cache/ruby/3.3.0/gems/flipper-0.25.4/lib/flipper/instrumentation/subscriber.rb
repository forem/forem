module Flipper
  module Instrumentation
    class Subscriber
      # Public: Use this as the subscribed block.
      def self.call(name, start, ending, transaction_id, payload)
        new(name, start, ending, transaction_id, payload).update
      end

      # Private: Initializes a new event processing instance.
      def initialize(name, start, ending, transaction_id, payload)
        @name = name
        @start = start
        @ending = ending
        @payload = payload
        @duration = ending - start
        @transaction_id = transaction_id
      end

      # Internal: Override in subclass.
      def update_timer(_metric)
        raise 'not implemented'
      end

      # Internal: Override in subclass.
      def update_counter(_metric)
        raise 'not implemented'
      end

      # Private
      def update
        operation_type = @name.split('.').first
        method_name = "update_#{operation_type}_metrics"

        if respond_to?(method_name)
          send(method_name)
        else
          puts "Could not update #{operation_type} metrics as #{self.class} " \
               "did not respond to `#{method_name}`"
        end
      end

      # Private
      def update_feature_operation_metrics
        feature_name = @payload[:feature_name]
        gate_name = @payload[:gate_name]
        operation = strip_trailing_question_mark(@payload[:operation])
        result = @payload[:result]
        thing = @payload[:thing]

        update_timer "flipper.feature_operation.#{operation}"

        if @payload[:operation] == :enabled?
          metric_name =
            if result
              "flipper.feature.#{feature_name}.enabled"
            else
              "flipper.feature.#{feature_name}.disabled"
            end

          update_counter metric_name
        end
      end

      # Private
      def update_adapter_operation_metrics
        adapter_name = @payload[:adapter_name]
        operation = @payload[:operation]
        result = @payload[:result]
        value = @payload[:value]
        key = @payload[:key]

        update_timer "flipper.adapter.#{adapter_name}.#{operation}"
      end

      QUESTION_MARK = '?'.freeze

      # Private
      def strip_trailing_question_mark(operation)
        operation.to_s.chomp(QUESTION_MARK)
      end
    end
  end
end
