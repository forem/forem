# frozen_string_literal: true

module Capybara
  module RSpecMatchers
    module SpatialSugar
      def above(el)
        options[:above] = el
        self
      end

      def below(el)
        options[:below] = el
        self
      end

      def left_of(el)
        options[:left_of] = el
        self
      end

      def right_of(el)
        options[:right_of] = el
        self
      end

      def near(el)
        options[:near] = el
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
