module Rpush
  module Redis
    module VERSION
      MAJOR = 1
      MINOR = 2
      TINY = 0
      PRE = nil

      STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".").freeze

      def self.to_s
        STRING
      end
    end
  end
end
