module Rpush
  module Daemon
    module StringHelpers
      def pluralize(count, singular, plural = nil)
        if count == 1
          word = singular
        else
          word = plural || singular.pluralize
        end

        "#{count || 0} #{word}"
      end
    end
  end
end
