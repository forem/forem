module Nenv
  class Environment
    module Loader::Default
      def self.call(raw_value)
        raw_value
      end
    end
  end
end
