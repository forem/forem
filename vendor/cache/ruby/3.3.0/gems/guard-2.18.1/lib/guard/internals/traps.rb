module Guard
  module Internals
    module Traps
      def self.handle(signal, &block)
        return unless Signal.list.key?(signal)
        Signal.trap(signal, &block)
      end
    end
  end
end
