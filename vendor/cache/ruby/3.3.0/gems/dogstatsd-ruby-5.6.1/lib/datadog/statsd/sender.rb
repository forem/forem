# frozen_string_literal: true

module Datadog
  class Statsd
    # Sender is using a companion thread to flush and pack messages
    # in a `MessageBuffer`.
    # The communication with this thread is done using a `Queue`.
    # If the thread is dead, it is starting a new one to avoid having a blocked
    # Sender with no companion thread to communicate with (most of the time, having
    # a dead companion thread means that a fork just happened and that we are
    # running in the child process).
    class Sender
      CLOSEABLE_QUEUES = Queue.instance_methods.include?(:close)

      def initialize(message_buffer, telemetry: nil, queue_size: UDP_DEFAULT_BUFFER_SIZE, logger: nil, flush_interval: nil, queue_class: Queue, thread_class: Thread)
        @message_buffer = message_buffer
        @telemetry = telemetry
        @queue_size = queue_size
        @logger = logger
        @mx = Mutex.new
        @queue_class = queue_class
        @thread_class = thread_class
        @flush_timer = if flush_interval
          Datadog::Statsd::Timer.new(flush_interval) { flush(sync: true) }
        else
          nil
        end
      end

      def flush(sync: false)
        # keep a copy around in case another thread is calling #stop while this method is running
        current_message_queue = message_queue

        # don't try to flush if there is no message_queue instantiated or
        # no companion thread running
        if !current_message_queue
          @logger.debug { "Statsd: can't flush: no message queue ready" } if @logger
          return
        end
        if !sender_thread.alive?
          @logger.debug { "Statsd: can't flush: no sender_thread alive" } if @logger
          return
        end

        current_message_queue.push(:flush)
        rendez_vous if sync
      end

      def rendez_vous
        # could happen if #start hasn't be called
        return unless message_queue

        # Initialize and get the thread's sync queue
        queue = (@thread_class.current[:statsd_sync_queue] ||= @queue_class.new)
        # tell sender-thread to notify us in the current
        # thread's queue
        message_queue.push(queue)
        # wait for the sender thread to send a message
        # once the flush is done
        queue.pop
      end

      def add(message)
        raise ArgumentError, 'Start sender first' unless message_queue

        # if the thread does not exist, we assume we are running in a forked process,
        # empty the message queue and message buffers (these messages belong to
        # the parent process) and spawn a new companion thread.
        if !sender_thread.alive?
          @mx.synchronize {
            # a call from another thread has already re-created
            # the companion thread before this one acquired the lock
            break if sender_thread.alive?
            @logger.debug { "Statsd: companion thread is dead, re-creating one" } if @logger

            message_queue.close if CLOSEABLE_QUEUES
            @message_queue = nil
            message_buffer.reset
            start
            @flush_timer.start if @flush_timer && @flush_timer.stop?
          }
        end

        if message_queue.length <= @queue_size
          message_queue << message
        else
          if @telemetry
            bytesize = message.respond_to?(:bytesize) ? message.bytesize : 0
            @telemetry.dropped_queue(packets: 1, bytes: bytesize)
          end
        end
      end

      def start
        raise ArgumentError, 'Sender already started' if message_queue

        # initialize a new message queue for the background thread
        @message_queue = @queue_class.new
        # start background thread
        @sender_thread = @thread_class.new(&method(:send_loop))
        @sender_thread.name = "Statsd Sender" unless Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')
        @flush_timer.start if @flush_timer
      end

      if CLOSEABLE_QUEUES
        # when calling stop, make sure that no other threads is trying
        # to close the sender nor trying to continue to `#add` more message
        # into the sender.
        def stop(join_worker: true)
          @flush_timer.stop if @flush_timer

          message_queue = @message_queue
          message_queue.close if message_queue

          sender_thread = @sender_thread
          sender_thread.join if sender_thread && join_worker
        end
      else
        # when calling stop, make sure that no other threads is trying
        # to close the sender nor trying to continue to `#add` more message
        # into the sender.
        def stop(join_worker: true)
          @flush_timer.stop if @flush_timer

          message_queue = @message_queue
          message_queue << :close if message_queue

          sender_thread = @sender_thread
          sender_thread.join if sender_thread && join_worker
        end
      end

      private

      attr_reader :message_buffer
      attr_reader :message_queue
      attr_reader :sender_thread

      if CLOSEABLE_QUEUES
        def send_loop
          until (message = message_queue.pop).nil? && message_queue.closed?
            # skip if message is nil, e.g. when message_queue
            # is empty and closed
            next unless message

            case message
            when :flush
              message_buffer.flush
            when @queue_class
              message.push(:go_on)
            else
              message_buffer.add(message)
            end
          end

          @message_queue = nil
          @sender_thread = nil
        end
      else
        def send_loop
          loop do
            message = message_queue.pop

            next unless message

            case message
            when :close
              break
            when :flush
              message_buffer.flush
            when @queue_class
              message.push(:go_on)
            else
              message_buffer.add(message)
            end
          end

          @message_queue = nil
          @sender_thread = nil
        end
      end
    end
  end
end
