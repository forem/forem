# frozen_string_literal: true

require 'thread'

module Puma
  # Internal Docs for A simple thread pool management object.
  #
  # Each Puma "worker" has a thread pool to process requests.
  #
  # First a connection to a client is made in `Puma::Server`. It is wrapped in a
  # `Puma::Client` instance and then passed to the `Puma::Reactor` to ensure
  # the whole request is buffered into memory. Once the request is ready, it is passed into
  # a thread pool via the `Puma::ThreadPool#<<` operator where it is stored in a `@todo` array.
  #
  # Each thread in the pool has an internal loop where it pulls a request from the `@todo` array
  # and processes it.
  class ThreadPool
    class ForceShutdown < RuntimeError
    end

    # How long, after raising the ForceShutdown of a thread during
    # forced shutdown mode, to wait for the thread to try and finish
    # up its work before leaving the thread to die on the vine.
    SHUTDOWN_GRACE_TIME = 5 # seconds

    # Maintain a minimum of +min+ and maximum of +max+ threads
    # in the pool.
    #
    # The block passed is the work that will be performed in each
    # thread.
    #
    def initialize(name, min, max, *extra, &block)
      @not_empty = ConditionVariable.new
      @not_full = ConditionVariable.new
      @mutex = Mutex.new

      @todo = []

      @spawned = 0
      @waiting = 0

      @name = name
      @min = Integer(min)
      @max = Integer(max)
      @block = block
      @extra = extra

      @shutdown = false

      @trim_requested = 0
      @out_of_band_pending = false

      @workers = []

      @auto_trim = nil
      @reaper = nil

      @mutex.synchronize do
        @min.times do
          spawn_thread
          @not_full.wait(@mutex)
        end
      end

      @clean_thread_locals = false
      @force_shutdown = false
      @shutdown_mutex = Mutex.new
    end

    attr_reader :spawned, :trim_requested, :waiting
    attr_accessor :clean_thread_locals
    attr_accessor :out_of_band_hook # @version 5.0.0

    def self.clean_thread_locals
      Thread.current.keys.each do |key| # rubocop: disable Style/HashEachMethods
        Thread.current[key] = nil unless key == :__recursive_key__
      end
    end

    # How many objects have yet to be processed by the pool?
    #
    def backlog
      with_mutex { @todo.size }
    end

    # @!attribute [r] pool_capacity
    def pool_capacity
      waiting + (@max - spawned)
    end

    # @!attribute [r] busy_threads
    # @version 5.0.0
    def busy_threads
      with_mutex { @spawned - @waiting + @todo.size }
    end

    # :nodoc:
    #
    # Must be called with @mutex held!
    #
    def spawn_thread
      @spawned += 1

      th = Thread.new(@spawned) do |spawned|
        Puma.set_thread_name '%s tp %03i' % [@name, spawned]
        todo  = @todo
        block = @block
        mutex = @mutex
        not_empty = @not_empty
        not_full = @not_full

        extra = @extra.map { |i| i.new }

        while true
          work = nil

          mutex.synchronize do
            while todo.empty?
              if @trim_requested > 0
                @trim_requested -= 1
                @spawned -= 1
                @workers.delete th
                not_full.signal
                Thread.exit
              end

              @waiting += 1
              if @out_of_band_pending && trigger_out_of_band_hook
                @out_of_band_pending = false
              end
              not_full.signal
              begin
                not_empty.wait mutex
              ensure
                @waiting -= 1
              end
            end

            work = todo.shift
          end

          if @clean_thread_locals
            ThreadPool.clean_thread_locals
          end

          begin
            @out_of_band_pending = true if block.call(work, *extra)
          rescue Exception => e
            STDERR.puts "Error reached top of thread-pool: #{e.message} (#{e.class})"
          end
        end
      end

      @workers << th

      th
    end

    private :spawn_thread

    # @version 5.0.0
    def trigger_out_of_band_hook
      return false unless out_of_band_hook && out_of_band_hook.any?

      # we execute on idle hook when all threads are free
      return false unless @spawned == @waiting

      out_of_band_hook.each(&:call)
      true
    rescue Exception => e
      STDERR.puts "Exception calling out_of_band_hook: #{e.message} (#{e.class})"
      true
    end

    private :trigger_out_of_band_hook

    # @version 5.0.0
    def with_mutex(&block)
      @mutex.owned? ?
        yield :
        @mutex.synchronize(&block)
    end

    # Add +work+ to the todo list for a Thread to pickup and process.
    def <<(work)
      with_mutex do
        if @shutdown
          raise "Unable to add work while shutting down"
        end

        @todo << work

        if @waiting < @todo.size and @spawned < @max
          spawn_thread
        end

        @not_empty.signal
      end
    end

    # This method is used by `Puma::Server` to let the server know when
    # the thread pool can pull more requests from the socket and
    # pass to the reactor.
    #
    # The general idea is that the thread pool can only work on a fixed
    # number of requests at the same time. If it is already processing that
    # number of requests then it is at capacity. If another Puma process has
    # spare capacity, then the request can be left on the socket so the other
    # worker can pick it up and process it.
    #
    # For example: if there are 5 threads, but only 4 working on
    # requests, this method will not wait and the `Puma::Server`
    # can pull a request right away.
    #
    # If there are 5 threads and all 5 of them are busy, then it will
    # pause here, and wait until the `not_full` condition variable is
    # signaled, usually this indicates that a request has been processed.
    #
    # It's important to note that even though the server might accept another
    # request, it might not be added to the `@todo` array right away.
    # For example if a slow client has only sent a header, but not a body
    # then the `@todo` array would stay the same size as the reactor works
    # to try to buffer the request. In that scenario the next call to this
    # method would not block and another request would be added into the reactor
    # by the server. This would continue until a fully buffered request
    # makes it through the reactor and can then be processed by the thread pool.
    def wait_until_not_full
      with_mutex do
        while true
          return if @shutdown

          # If we can still spin up new threads and there
          # is work queued that cannot be handled by waiting
          # threads, then accept more work until we would
          # spin up the max number of threads.
          return if busy_threads < @max

          @not_full.wait @mutex
        end
      end
    end

    # @version 5.0.0
    def wait_for_less_busy_worker(delay_s)
      return unless delay_s && delay_s > 0

      # Ruby MRI does GVL, this can result
      # in processing contention when multiple threads
      # (requests) are running concurrently
      return unless Puma.mri?

      with_mutex do
        return if @shutdown

        # do not delay, if we are not busy
        return unless busy_threads > 0

        # this will be signaled once a request finishes,
        # which can happen earlier than delay
        @not_full.wait @mutex, delay_s
      end
    end

    # If there are any free threads in the pool, tell one to go ahead
    # and exit. If +force+ is true, then a trim request is requested
    # even if all threads are being utilized.
    #
    def trim(force=false)
      with_mutex do
        free = @waiting - @todo.size
        if (force or free > 0) and @spawned - @trim_requested > @min
          @trim_requested += 1
          @not_empty.signal
        end
      end
    end

    # If there are dead threads in the pool make them go away while decreasing
    # spawned counter so that new healthy threads could be created again.
    def reap
      with_mutex do
        dead_workers = @workers.reject(&:alive?)

        dead_workers.each do |worker|
          worker.kill
          @spawned -= 1
        end

        @workers.delete_if do |w|
          dead_workers.include?(w)
        end
      end
    end

    class Automaton
      def initialize(pool, timeout, thread_name, message)
        @pool = pool
        @timeout = timeout
        @thread_name = thread_name
        @message = message
        @running = false
      end

      def start!
        @running = true

        @thread = Thread.new do
          Puma.set_thread_name @thread_name
          while @running
            @pool.public_send(@message)
            sleep @timeout
          end
        end
      end

      def stop
        @running = false
        @thread.wakeup
      end
    end

    def auto_trim!(timeout=30)
      @auto_trim = Automaton.new(self, timeout, "#{@name} threadpool trimmer", :trim)
      @auto_trim.start!
    end

    def auto_reap!(timeout=5)
      @reaper = Automaton.new(self, timeout, "#{@name} threadpool reaper", :reap)
      @reaper.start!
    end

    # Allows ThreadPool::ForceShutdown to be raised within the
    # provided block if the thread is forced to shutdown during execution.
    def with_force_shutdown
      t = Thread.current
      @shutdown_mutex.synchronize do
        raise ForceShutdown if @force_shutdown
        t[:with_force_shutdown] = true
      end
      yield
    ensure
      t[:with_force_shutdown] = false
    end

    # Tell all threads in the pool to exit and wait for them to finish.
    # Wait +timeout+ seconds then raise +ForceShutdown+ in remaining threads.
    # Next, wait an extra +grace+ seconds then force-kill remaining threads.
    # Finally, wait +kill_grace+ seconds for remaining threads to exit.
    #
    def shutdown(timeout=-1)
      threads = with_mutex do
        @shutdown = true
        @trim_requested = @spawned
        @not_empty.broadcast
        @not_full.broadcast

        @auto_trim.stop if @auto_trim
        @reaper.stop if @reaper
        # dup workers so that we join them all safely
        @workers.dup
      end

      if timeout == -1
        # Wait for threads to finish without force shutdown.
        threads.each(&:join)
      else
        join = ->(inner_timeout) do
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          threads.reject! do |t|
            elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
            t.join inner_timeout - elapsed
          end
        end

        # Wait +timeout+ seconds for threads to finish.
        join.call(timeout)

        # If threads are still running, raise ForceShutdown and wait to finish.
        @shutdown_mutex.synchronize do
          @force_shutdown = true
          threads.each do |t|
            t.raise ForceShutdown if t[:with_force_shutdown]
          end
        end
        join.call(SHUTDOWN_GRACE_TIME)

        # If threads are _still_ running, forcefully kill them and wait to finish.
        threads.each(&:kill)
        join.call(1)
      end

      @spawned = 0
      @workers = []
    end
  end
end
