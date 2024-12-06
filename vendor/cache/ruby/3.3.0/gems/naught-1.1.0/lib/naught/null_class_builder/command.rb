module Naught
  class NullClassBuilder
    class Command
      attr_reader :builder

      def initialize(builder)
        @builder = builder
      end

      def call
        fail(NotImplementedError.new('Method #call should be overriden in child classes'))
      end

      def defer(options = {}, &block)
        @builder.defer(options, &block)
      end
    end
  end
end
