require 'securerandom'
require 'active_support/notifications'
require 'active_support/log_subscriber'

module Flipper
  module Instrumentation
    class LogSubscriber < ::ActiveSupport::LogSubscriber
      # Logs a feature operation.
      #
      # Example Output
      #
      #   flipper[:search].enabled?(user)
      #   # Flipper feature(search) enabled? false (1.2ms)  [ thing=... ]
      #
      # Returns nothing.
      def feature_operation(event)
        return unless logger.debug?

        feature_name = event.payload[:feature_name]
        gate_name = event.payload[:gate_name]
        operation = event.payload[:operation]
        result = event.payload[:result]
        thing = event.payload[:thing]

        description = "Flipper feature(#{feature_name}) #{operation} #{result.inspect}"
        details = "thing=#{thing.inspect}"

        details += " gate_name=#{gate_name}" unless gate_name.nil?

        name = '%s (%.1fms)' % [description, event.duration]
        debug "  #{color(name, CYAN, true)}  [ #{details} ]"
      end

      # Logs an adapter operation. If operation is for a feature, then that
      # feature is included in log output.
      #
      # Example Output
      #
      #   # log output for adapter operation with feature
      #   # Flipper feature(search) adapter(memory) enable  (0.0ms)  [ result=...]
      #
      #   # log output for adapter operation with no feature
      #   # Flipper adapter(memory) features (0.0ms)  [ result=... ]
      #
      # Returns nothing.
      def adapter_operation(event)
        return unless logger.debug?

        feature_name = event.payload[:feature_name]
        adapter_name = event.payload[:adapter_name]
        gate_name = event.payload[:gate_name]
        operation = event.payload[:operation]
        result = event.payload[:result]

        description = 'Flipper '
        description << "feature(#{feature_name}) " unless feature_name.nil?
        description << "adapter(#{adapter_name}) "
        description << "#{operation} "

        details = "result=#{result.inspect}"

        name = '%s (%.1fms)' % [description, event.duration]
        debug "  #{color(name, CYAN, true)}  [ #{details} ]"
      end

      def logger
        self.class.logger
      end
    end
  end

  Instrumentation::LogSubscriber.attach_to InstrumentationNamespace
end
