module Rpush
  module Daemon
    class Delivery
      include Reflectable
      include Loggable

      def mark_retryable(notification, deliver_after, error = nil)
        if notification.fail_after && notification.fail_after < Time.now
          @batch.mark_failed(notification, nil, "Notification failed to be delivered before #{notification.fail_after.strftime('%Y-%m-%d %H:%M:%S')}.")
        else
          if error
            log_warn("Will retry notification #{notification.id} after #{deliver_after.strftime('%Y-%m-%d %H:%M:%S')} due to error (#{error.class.name}, #{error.message})")
          end
          @batch.mark_retryable(notification, deliver_after)
        end
      end

      def mark_retryable_exponential(notification)
        mark_retryable(notification, Time.now + 2**(notification.retries + 1))
      end

      def mark_batch_retryable(deliver_after, error)
        @batch.mark_all_retryable(deliver_after, error)
      end

      def mark_delivered
        @batch.mark_delivered(@notification)
      end

      def mark_batch_delivered
        @batch.mark_all_delivered
      end

      def mark_failed(error)
        code = error.respond_to?(:code) ? error.code : nil
        @batch.mark_failed(@notification, code, error.to_s)
      end

      def mark_batch_failed(error)
        code = error.respond_to?(:code) ? error.code : nil
        @batch.mark_all_failed(code, error.to_s)
      end
    end
  end
end
