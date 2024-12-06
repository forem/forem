##
# SizedQueueWithTimeout is copyright and licensed per the LICENSE.txt in
# its containing subdirectory of this codebase.
#
module Libhoney
  module Queueing
    ##
    # A queue implementation with optional size limit and optional timeouts on pop and push
    # operations. Heavily influenced / liberally mimicking Avdi Grimm's
    # {Tapas::Queue}[https://github.com/avdi/tapas-queue].
    #
    class SizedQueueWithTimeout
      class PushTimedOut < ThreadError; end
      class PopTimedOut < ThreadError; end

      ##
      # @param max_size [Integer, Float::INFINITY] the size limit for this queue
      # @param options [Hash] optional dependencies to inject, primarily for testing
      # @option options [QLock, Mutex] :lock the lock for synchronizing queue state change
      # @option options [QCondition] :space_available_condition the condition variable
      #   to wait/signal on for space being available in the queue; when provided, must
      #   be accompanied by an +:item_available_condition+ and the shared +:lock+
      # @option options [QCondition] :item_available_condition the condition variable
      #   to wait/signal on for an item being added to the queue; when provided, must
      #   be accompanied by an +:space_available_condition+ and the shared +:lock+
      def initialize(max_size = Float::INFINITY, options = {})
        @items           = []
        @max_size        = max_size
        @lock            = options.fetch(:lock) { QLock.new }
        @space_available = options.fetch(:space_available_condition) { QCondition.new(@lock) }
        @item_available  = options.fetch(:item_available_condition) { QCondition.new(@lock) }
      end

      ##
      # Push something onto the queue.
      #
      # @param obj [Object] the thing to add to the queue
      # @param timeout [Numeric, :never] how long in seconds to wait for the queue to have space available or
      #   +:never+ to wait "forever"
      # @param timeout_policy [#call] defaults to +-> { raise PushTimedOut }+ - a lambda/Proc/callable, what to do
      #   when the timeout expires
      #
      # @raise {PushTimedOut}
      def push(obj, timeout = :never, &timeout_policy)
        timeout_policy ||= -> { raise PushTimedOut }

        wait_for_condition(@space_available, -> { !full? }, timeout, timeout_policy) do
          @items.push(obj)
          @item_available.signal
        end
      end
      alias enq push
      alias << push

      ##
      # Pop something off the queue.
      #
      # @param timeout [Numeric, :never] how long in seconds to wait for the queue to have an item available or
      #   +:never+ to wait "forever"
      # @param timeout_policy [#call] defaults to +-> { raise PopTimedOut }+ - a lambda/Proc/callable, what to do
      #   when the timeout expires
      #
      # @return [Object]
      # @raise {PopTimedOut}
      def pop(timeout = :never, &timeout_policy)
        timeout_policy ||= -> { raise PopTimedOut }

        wait_for_condition(@item_available, -> { !empty? }, timeout, timeout_policy) do
          item = @items.shift
          @space_available.signal unless full?
          item
        end
      end
      alias deq pop
      alias shift pop

      ##
      # Removes all objects from the queue. They are cast into the abyss never to be seen again.
      #
      def clear
        @lock.synchronize do
          @items = []
          @space_available.signal unless full?
        end
      end

      private

      ##
      # Whether the queue is at capacity. Must be called with the queue's lock
      # or the answer won't matter if you try to change state based on it.
      #
      # @return [true/false]
      # @api private
      def full?
        @max_size <= @items.size
      end

      ##
      # Whether the queue is empty. Must be called with the queue's lock or the
      # answer won't matter if you try to change state based on it.
      #
      # @return [true/false]
      # @api private
      def empty?
        @items.empty?
      end

      # a generic conditional variable wait with a timeout loop
      #
      # @param condition [#wait] a condition variable to wait upon.
      # @param condition_predicate [#call] a callable (i.e. lambda or proc) that returns true/false to act
      #   as a state tester (i.e. "is the queue currently empty?") to check on whether to keep waiting;
      #   used to handle spurious wake ups occurring before the timeout has elapsed
      # @param timeout [:never, Numeric] the amount of time in (seconds?) to wait, or :never to wait forever
      # @param timeout_policy [#call] a callable, what to do when a timeout occurs? Return a default? Raise an
      #   exception? You decide.
      def wait_for_condition(condition, condition_predicate, timeout = :never, timeout_policy = -> {})
        deadline = timeout == :never ? :never : trustworthy_current_time + timeout
        @lock.synchronize do
          loop do
            time_remaining = timeout == :never ? nil : deadline - trustworthy_current_time

            if !condition_predicate.call && time_remaining.to_f >= 0 # rubocop:disable Style/IfUnlessModifier
              condition.wait(time_remaining)
            end

            if condition_predicate.call # rubocop:disable Style/GuardClause
              return yield
            elsif deadline == :never || deadline > trustworthy_current_time
              next
            else
              return timeout_policy.call
            end
          end
        end
      end

      # Within the context of the current process, return time from a
      # monotonically increasing clock because for timeouts we care about
      # elapsed time within the process, not human time.
      #
      # @return [Numeric]
      def trustworthy_current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end

    class QCondition
      def initialize(lock)
        @lock = lock
        @cv   = ConditionVariable.new
      end

      def wait(timeout = nil)
        @cv.wait(@lock.mutex, timeout)
      end

      def signal
        @cv.signal
      end
    end

    class QLock
      attr_reader :mutex

      def initialize
        @mutex = Mutex.new
      end

      def synchronize(&block)
        @mutex.synchronize(&block)
      end
    end
  end
end
