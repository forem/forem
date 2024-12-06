# frozen_string_literal: true

module Capybara
  module RSpecMatchers
    module CountSugar
      def once; exactly(1); end
      def twice; exactly(2); end
      def thrice; exactly(3); end

      def exactly(number)
        options[:count] = number
        self
      end

      def at_most(number)
        options[:maximum] = number
        self
      end

      def at_least(number)
        options[:minimum] = number
        self
      end

      def times
        self
      end

    private

      def options
        # (@args.last.is_a?(Hash) ? @args : @args.push({})).last
        @kw_args
      end
    end
  end
end
