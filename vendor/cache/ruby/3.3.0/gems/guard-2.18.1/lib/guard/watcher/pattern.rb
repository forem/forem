require "guard/ui"

require_relative "pattern/match_result"
require_relative "pattern/matcher"
require_relative "pattern/deprecated_regexp"
require_relative "pattern/simple_path"
require_relative "pattern/pathname_path"

module Guard
  class Watcher
    class Pattern
      def self.create(pattern)
        if DeprecatedRegexp.new(pattern).deprecated?
          DeprecatedRegexp.show_deprecation(pattern)
          return DeprecatedRegexp.convert(pattern)
        end

        return PathnamePath.new(pattern) if pattern.is_a?(Pathname)
        return SimplePath.new(pattern) if pattern.is_a?(String)
        Matcher.new(pattern)
      end
    end
  end
end
