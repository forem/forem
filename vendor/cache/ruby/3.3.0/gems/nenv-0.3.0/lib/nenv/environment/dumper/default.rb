module Nenv
  class Environment
    module Dumper::Default
      def self.call(raw_value)
        raw_value.nil? ? nil : raw_value.to_s
      end
    end
  end
end
