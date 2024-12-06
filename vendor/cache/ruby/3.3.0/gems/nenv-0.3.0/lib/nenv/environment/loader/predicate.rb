module Nenv
  class Environment
    module Loader::Predicate
      def self.call(raw_value)
        case raw_value
        when nil
          nil
        when ''
          fail ArgumentError, "Can't convert empty string into Bool"
        when '0', 'false', 'n', 'no', 'NO', 'FALSE'
          false
        else
          true
        end
      end
    end
  end
end
