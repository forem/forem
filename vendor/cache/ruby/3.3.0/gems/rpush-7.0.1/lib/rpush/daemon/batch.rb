module Rpush
  module Daemon
    class Batch
      include Reflectable
      include Loggable

      attr_reader :num_processed, :notifications, :delivered, :failed, :retryable

      def initialize(notifications)
        @notifications = notifications
        @num_processed = 0
        @delivered = []
        @failed = {}
        @retryable = {}
        @mutex = Mutex.new
      end

      def complete?
        @complete == true
      end

      def each_notification(&blk)
        @notifications.each(&blk)
      end

      def each_delivered(&blk)
        @delivered.each(&blk)
      end

      def mark_retryable(notification, deliver_after)
        @mutex.synchronize do
          @retryable[deliver_after] ||= []
          @retryable[deliver_after] << notification
        end

        Rpush::Daemon.store.mark_retryable(notification, deliver_after, persist: false)
      end

      def mark_all_retryable(deliver_after, error)
        retryable_count = 0

        each_notification do |notification|
          next if notification.delivered || notification.failed

          retryable_count += 1
          mark_retryable(notification, deliver_after)
        end

        log_warn("Will retry #{retryable_count} of #{@notifications.size} notifications after #{deliver_after.strftime('%Y-%m-%d %H:%M:%S')} due to error (#{error.class.name}, #{error.message})")
      end

      def mark_delivered(notification)
        @mutex.synchronize do
          @delivered << notification
        end
        Rpush::Daemon.store.mark_delivered(notification, Time.now, persist: false)
      end

      def mark_all_delivered
        @mutex.synchronize do
          @delivered = @notifications
        end

        each_notification do |notification|
          Rpush::Daemon.store.mark_delivered(notification, Time.now, persist: false)
        end
      end

      def mark_failed(notification, code, description)
        key = [code, description]
        @mutex.synchronize do
          @failed[key] ||= []
          @failed[key] << notification
        end
        Rpush::Daemon.store.mark_failed(notification, code, description, Time.now, persist: false)
      end

      def mark_all_failed(code, message)
        key = [code, message]
        @mutex.synchronize do
          @failed[key] = @notifications
        end
        each_notification do |notification|
          Rpush::Daemon.store.mark_failed(notification, code, message, Time.now, persist: false)
        end
      end

      def notification_processed
        @mutex.synchronize do
          @num_processed += 1
          complete if @num_processed >= @notifications.size
        end
      end

      def all_processed
        @mutex.synchronize do
          @num_processed = @notifications.size
          complete
        end
      end

      private

      def complete
        return if complete?

        [:complete_delivered, :complete_failed, :complete_retried].each do |method|
          begin
            send(method)
          rescue StandardError => e
            Rpush.logger.error(e)
            reflect(:error, e)
          end
        end

        @complete = true
      end

      def complete_delivered
        Rpush::Daemon.store.mark_batch_delivered(@delivered)
        @delivered.each do |notification|
          reflect(:notification_delivered, notification)
        end
      end

      def complete_failed
        @failed.each do |(code, description), notifications|
          Rpush::Daemon.store.mark_batch_failed(notifications, code, description)
          notifications.each do |notification|
            reflect(:notification_failed, notification)
          end
        end
      end

      def complete_retried
        @retryable.each do |deliver_after, notifications|
          Rpush::Daemon.store.mark_batch_retryable(notifications, deliver_after)
          notifications.each do |notification|
            reflect(:notification_will_retry, notification)
          end
        end
      end
    end
  end
end
