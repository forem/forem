module RSpec
  module Core
    class Example
      attr_accessor :attempts

      def clear_exception
        @exception = nil
      end

      class Procsy
        def run_with_retry(opts = {})
          RSpec::Retry.new(self, opts).run
        end

        def attempts
          @example.attempts
        end
      end
    end
  end
end

module RSpec
  module Core
    class ExampleGroup
      def clear_memoized
        if respond_to? :__init_memoized, true
          __init_memoized
        else
          @__memoized = nil
        end
      end

      def clear_lets
        clear_memoized
      end
    end
  end
end
