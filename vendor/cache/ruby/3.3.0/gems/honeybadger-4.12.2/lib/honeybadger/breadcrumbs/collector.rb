require 'forwardable'

module Honeybadger
  module Breadcrumbs
    class Collector
      include Enumerable
      extend Forwardable
      # The Collector manages breadcrumbs and provides an interface for accessing
      # and affecting breadcrumbs
      #
      # Most actions are delegated to the current buffer implementation. A
      # Buffer must implement all delegated methods to work with the Collector.

      # Flush all breadcrumbs, delegates to buffer
      def_delegator :@buffer, :clear!

      # Iterate over all Breadcrumbs and satify Enumerable, delegates to buffer
      # @yield [Object] sequentially gives breadcrumbs to the block
      def_delegator :@buffer, :each

      # Raw Array of Breadcrumbs, delegates to buffer
      # @return [Array] Raw set of breadcrumbs
      def_delegator :@buffer, :to_a

      # Last item added to the buffer
      # @return [Breadcrumb]
      def_delegator :@buffer, :previous

      def initialize(config, buffer = RingBuffer.new)
        @config = config
        @buffer = buffer
      end

      # Add Breadcrumb to stack
      #
      # @return [self] Filtered breadcrumbs
      def add!(breadcrumb)
        return unless @config[:'breadcrumbs.enabled']
        @buffer.add!(breadcrumb)

        self
      end

      alias_method :<<, :add!

      # @api private
      # Removes the prevous breadcrumb from the buffer if the supplied
      # block returns a falsy value
      #
      def drop_previous_breadcrumb_if
        @buffer.drop if (previous && block_given? && yield(previous))
      end

      # All active breadcrumbs you want to remove a breadcrumb from the trail,
      # then you can selectively ignore breadcrumbs while building a notice.
      #
      # @return [Array] Active breadcrumbs
      def trail
        select(&:active?)
      end

      def to_h
        {
          enabled: @config[:'breadcrumbs.enabled'],
          trail: trail.map(&:to_h)
        }
      end

      private

      # @api private
      # Since the collector is shared with the worker thread, there is a chance
      # it can be cleared before we have prepared the request. We provide the
      # ability to duplicate a collector which should also duplicate the buffer
      # instance, as that holds the breadcrumbs.
      def initialize_dup(source)
        @buffer = source.instance_variable_get(:@buffer).dup
        super
      end
    end
  end
end
