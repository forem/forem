module Timber
  # The Timber Logger behaves exactly like the standard Ruby `::Logger`, except that it supports a
  # transparent API for logging structured data and events.
  #
  # @example Basic logging
  #   logger.info "Payment rejected for customer #{customer_id}"
  #
  # @example Logging an event
  #   logger.info "Payment rejected", payment_rejected: {customer_id: customer_id, amount: 100}
  class Logger < ::Logger
    include ::ActiveSupport::LoggerThreadSafeLevel if defined?(::ActiveSupport::LoggerThreadSafeLevel)

    if defined?(::ActiveSupport::LoggerSilence)
      include ::ActiveSupport::LoggerSilence
    elsif defined?(::LoggerSilence)
      include ::LoggerSilence
    end
  end
end

