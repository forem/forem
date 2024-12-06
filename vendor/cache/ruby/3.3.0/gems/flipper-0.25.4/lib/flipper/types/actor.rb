module Flipper
  module Types
    class Actor < Type
      def self.wrappable?(thing)
        return false if thing.nil?
        thing.respond_to?(:flipper_id)
      end

      attr_reader :thing

      def initialize(thing)
        raise ArgumentError, 'thing cannot be nil' if thing.nil?

        unless thing.respond_to?(:flipper_id)
          raise ArgumentError, "#{thing.inspect} must respond to flipper_id, but does not"
        end

        @thing = thing
        @value = thing.flipper_id.to_s
      end

      def respond_to?(*args)
        super || @thing.respond_to?(*args)
      end

      if RUBY_VERSION >= '3.0'
        def method_missing(name, *args, **kwargs, &block)
          @thing.send name, *args, **kwargs, &block
        end
      else
        def method_missing(name, *args, &block)
          @thing.send name, *args, &block
        end
      end
    end
  end
end
