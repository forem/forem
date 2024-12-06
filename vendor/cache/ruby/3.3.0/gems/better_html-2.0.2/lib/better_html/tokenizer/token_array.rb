# frozen_string_literal: true

module BetterHtml
  module Tokenizer
    class TokenArray
      def initialize(list)
        @list = list
        @current = 0
        @last = @list.size
      end

      def shift
        raise "no tokens left to shift" if empty?

        item = @list[@current]
        @current += 1
        item
      end

      def pop
        raise "no tokens left to pop" if empty?

        item = @list[@last - 1]
        @last -= 1
        item
      end

      def trim(type)
        shift while current&.type == type
        pop while last&.type == type
      end

      def empty?
        size <= 0
      end

      def any?
        !empty?
      end

      def current
        @list[@current] unless empty?
      end

      def last
        @list[@last - 1] unless empty?
      end

      def size
        @last - @current
      end
    end
  end
end
