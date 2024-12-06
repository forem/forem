# frozen_string_literal: true

module Ferrum
  class Browser
    class Subscriber
      include Concurrent::Async

      def self.build(size)
        (0..size).map { new }
      end

      def initialize
        super
        @on = Concurrent::Hash.new { |h, k| h[k] = Concurrent::Array.new }
      end

      def on(event, &block)
        @on[event] << block
        true
      end

      def subscribed?(event)
        @on.key?(event)
      end

      def call(message)
        method, params = message.values_at("method", "params")
        total = @on[method].size
        @on[method].each_with_index do |block, index|
          # In case of multiple callbacks we provide current index and total
          block.call(params, index, total)
        end
      end
    end
  end
end
