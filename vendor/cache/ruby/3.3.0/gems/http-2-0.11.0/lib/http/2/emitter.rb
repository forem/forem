module HTTP2
  # Basic event emitter implementation with support for persistent and
  # one-time event callbacks.
  #
  module Emitter
    # Subscribe to all future events for specified type.
    #
    # @param event [Symbol]
    # @param block [Proc] callback function
    def add_listener(event, &block)
      fail ArgumentError, 'must provide callback' unless block_given?
      listeners(event.to_sym).push block
    end
    alias on add_listener

    # Subscribe to next event (at most once) for specified type.
    #
    # @param event [Symbol]
    # @param block [Proc] callback function
    def once(event, &block)
      add_listener(event) do |*args, &callback|
        block.call(*args, &callback)
        :delete
      end
    end

    # Emit event with provided arguments.
    #
    # @param event [Symbol]
    # @param args [Array] arguments to be passed to the callbacks
    # @param block [Proc] callback function
    def emit(event, *args, &block)
      listeners(event).delete_if do |cb|
        cb.call(*args, &block) == :delete
      end
    end

    private

    def listeners(event)
      @listeners ||= Hash.new { |hash, key| hash[key] = [] }
      @listeners[event]
    end
  end
end
