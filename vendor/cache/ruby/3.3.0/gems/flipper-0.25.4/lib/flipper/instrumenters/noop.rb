module Flipper
  module Instrumenters
    class Noop
      def self.instrument(_name, payload = {})
        yield payload if block_given?
      end
    end
  end
end
