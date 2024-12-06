# frozen_string_literal: true

require 'puma/queue_close' unless ::Queue.instance_methods.include? :close

module Puma
  class UnsupportedBackend < StandardError; end

  # Monitors a collection of IO objects, calling a block whenever
  # any monitored object either receives data or times out, or when the Reactor shuts down.
  #
  # The waiting/wake up is performed with nio4r, which will use the appropriate backend (libev,
  # Java NIO or just plain IO#select). The call to `NIO::Selector#select` will
  # 'wakeup' any IO object that receives data.
  #
  # This class additionally tracks a timeout for every added object,
  # and wakes up any object when its timeout elapses.
  #
  # The implementation uses a Queue to synchronize adding new objects from the internal select loop.
  class Reactor
    # Create a new Reactor to monitor IO objects added by #add.
    # The provided block will be invoked when an IO has data available to read,
    # its timeout elapses, or when the Reactor shuts down.
    def initialize(backend, &block)
      require 'nio'
      unless backend == :auto || NIO::Selector.backends.include?(backend)
        raise "unsupported IO selector backend: #{backend} (available backends: #{NIO::Selector.backends.join(', ')})"
      end
      @selector = backend == :auto ? NIO::Selector.new : NIO::Selector.new(backend)
      @input = Queue.new
      @timeouts = []
      @block = block
    end

    # Run the internal select loop, using a background thread by default.
    def run(background=true)
      if background
        @thread = Thread.new do
          Puma.set_thread_name "reactor"
          select_loop
        end
      else
        select_loop
      end
    end

    # Add a new client to monitor.
    # The object must respond to #timeout and #timeout_at.
    # Returns false if the reactor is already shut down.
    def add(client)
      @input << client
      @selector.wakeup
      true
    rescue ClosedQueueError
      false
    end

    # Shutdown the reactor, blocking until the background thread is finished.
    def shutdown
      @input.close
      begin
        @selector.wakeup
      rescue IOError # Ignore if selector is already closed
      end
      @thread.join if @thread
    end

    private

    def select_loop
      begin
        until @input.closed? && @input.empty?
          # Wakeup any registered object that receives incoming data.
          # Block until the earliest timeout or Selector#wakeup is called.
          timeout = (earliest = @timeouts.first) && earliest.timeout
          @selector.select(timeout) {|mon| wakeup!(mon.value)}

          # Wakeup all objects that timed out.
          timed_out = @timeouts.take_while {|t| t.timeout == 0}
          timed_out.each(&method(:wakeup!))

          unless @input.empty?
            until @input.empty?
              client = @input.pop
              register(client) if client.io_ok?
            end
            @timeouts.sort_by!(&:timeout_at)
          end
        end
      rescue StandardError => e
        STDERR.puts "Error in reactor loop escaped: #{e.message} (#{e.class})"
        STDERR.puts e.backtrace
        retry
      end
      # Wakeup all remaining objects on shutdown.
      @timeouts.each(&@block)
      @selector.close
    end

    # Start monitoring the object.
    def register(client)
      @selector.register(client.to_io, :r).value = client
      @timeouts << client
    rescue ArgumentError
      # unreadable clients raise error when processed by NIO
    end

    # 'Wake up' a monitored object by calling the provided block.
    # Stop monitoring the object if the block returns `true`.
    def wakeup!(client)
      if @block.call client
        @selector.deregister client.to_io
        @timeouts.delete client
      end
    end
  end
end
