module Flipper
  module Types
    class Group < Type
      def self.wrap(group_or_name)
        return group_or_name if group_or_name.is_a?(self)
        Flipper.group(group_or_name)
      end

      attr_reader :name

      def initialize(name, &block)
        @name = name.to_sym
        @value = @name

        if block_given?
          @block = block
          @single_argument = call_with_no_context?(@block)
        else
          @block = ->(_thing, _context) { false }
          @single_argument = false
        end
      end

      def match?(thing, context)
        if @single_argument
          @block.call(thing)
        else
          @block.call(thing, context)
        end
      end

      NO_PARAMS_IN_RUBY_3 = [[:req], [:rest]]
      def call_with_no_context?(block)
        return true if block.parameters == NO_PARAMS_IN_RUBY_3

        block.arity.abs == 1
      end
    end
  end
end
