require 'libhoney/queueing'
require 'libhoney/transmission'

module Libhoney
  ##
  # An experimental variant of the standard {TransmissionClient} that uses
  # a custom implementation of a sized queue whose pop/push methods support
  # a timeout internally.
  #
  # @example Use this transmission with the Ruby Beeline
  #   require 'libhoney/experimental_transmission'
  #
  #   Honeycomb.configure do |config|
  #     config.client = Libhoney::Client.new(
  #       writekey: ENV["HONEYCOMB_WRITE_KEY"],
  #       dataset: ENV.fetch("HONEYCOMB_DATASET", "awesome_sauce"),
  #       transmission: Libhoney::ExperimentalTransmissionClient
  #     )
  #     ...
  #   end
  #
  # @api private
  #
  class ExperimentalTransmissionClient < TransmissionClient
    def add(event)
      return unless event_valid(event)

      begin
        # if block_on_send is true, never timeout the wait to enqueue an event
        # otherwise, timeout the wait immediately and if the queue is full, we'll
        # have a ThreadError raised because we could not add to the queue.
        timeout = @block_on_send ? :never : 0
        @batch_queue.enq(event, timeout)
      rescue Libhoney::Queueing::SizedQueueWithTimeout::PushTimedOut
        # happens if the queue was full and block_on_send = false.
        warn "#{self.class.name}: batch queue full, dropping event." if %w[debug trace].include?(ENV['LOG_LEVEL'])
      end

      ensure_threads_running
    end

    def batch_loop
      next_send_time = Time.now + @send_frequency
      batched_events = Hash.new do |h, key|
        h[key] = []
      end

      loop do
        begin
          # an event on the batch_queue
          #   1. pops out and is truthy
          #   2. gets included in the current batch
          #   3. while waits for another event
          while (event = @batch_queue.pop(@send_frequency))
            key = [event.api_host, event.writekey, event.dataset]
            batched_events[key] << event
          end

          # a nil on the batch_queue
          #   1. pops out and is falsy
          #   2. ends the event-popping while do..end
          #   3. breaks the loop
          #   4. flushes the current batch
          #   5. ends the batch_loop
          break

        # a timeout expiration waiting for an event
        #   1. skips the break and is rescued
        #   2. triggers the ensure to flush the current batch
        #   3. begins the loop again with an updated next_send_time
        rescue Libhoney::Queueing::SizedQueueWithTimeout::PopTimedOut => e
          warn "#{self.class.name}: ⏱ " + e.message if %w[trace].include?(ENV['LOG_LEVEL'])

        # any exception occurring in this loop should not take down the actual
        # instrumented Ruby process, so handle here and log that there is trouble
        rescue Exception => e
          warn "#{self.class.name}: 💥 " + e.message if %w[debug trace].include?(ENV['LOG_LEVEL'])
          warn e.backtrace.join("\n").to_s if ['trace'].include?(ENV['LOG_LEVEL'])

        # regardless of the exception, figure out whether enough time has passed to
        # send the current batched events, if so, send them and figure out the next send time
        # before going back to the top of the loop
        ensure
          next_send_time = flush_batched_events(batched_events) if Time.now > next_send_time
        end
      end

      # don't need to capture the next_send_time here because the batch_loop is exiting
      # for some reason (probably transmission.close)
      flush_batched_events(batched_events)
    end

    private

    def setup_batch_queue
      # override super()'s @batch_queue = SizedQueue.new(); use our SizedQueueWithTimeout:
      # + block on adding events to the batch_queue when queue is full and @block_on_send is true
      # + the queue knows how to limit size and how to time-out pushes and pops
      @batch_queue = Libhoney::Queueing::SizedQueueWithTimeout.new(@pending_work_capacity)
      warn "⚠️🐆 #{self.class.name} in use! It may drop data, consume all your memory, or cause skin irritation."
    end

    def build_user_agent(user_agent_addition)
      super("(exp-transmission) #{user_agent_addition}".strip)
    end
  end
end
