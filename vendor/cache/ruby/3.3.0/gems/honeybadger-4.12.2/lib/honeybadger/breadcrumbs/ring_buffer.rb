module Honeybadger
  module Breadcrumbs
    class RingBuffer
      # Simple ring buffer implementation that keeps item count constrained using
      # a rolling window. Items from the front of the buffer are dropped as more
      # are pushed on the end of the stack.
      include Enumerable

      attr_reader :buffer

      def initialize(buffer_size = 40)
        @buffer_size = buffer_size
        clear!
      end

      def add!(item)
        @buffer << item
        @ct += 1
        @buffer.shift(1) if @ct > @buffer_size
      end

      def clear!
        @buffer = []
        @ct = 0
      end

      def to_a
        @buffer
      end

      def each(&blk)
        @buffer.each(&blk)
      end

      def previous
        @buffer.last
      end

      def drop
        @buffer.pop
      end
    end
  end
end
