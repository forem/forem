require_relative "matcher"

module Guard
  class Watcher
    class Pattern
      # TODO: remove before Guard 3.x
      class DeprecatedRegexp
        def initialize(pattern)
          @original_pattern = pattern
        end

        def self.convert(pattern)
          Matcher.new(Regexp.new(pattern))
        end

        def deprecated?
          regexp = /(^(\^))|(>?(\\\.)|(\.\*))|(\(.*\))|(\[.*\])|(\$$)/
          @original_pattern.is_a?(String) && regexp.match(@original_pattern)
        end

        def self.show_deprecation(pattern)
          @warning_printed ||= false

          unless @warning_printed
            msg = "*" * 20 + "\nDEPRECATION WARNING!\n" + "*" * 20
            msg += <<-MSG
            You have a string in your Guardfile watch patterns that seem to
            represent a Regexp.

            Guard matches String with == and Regexp with Regexp#match.

            You should either use plain String (without Regexp special
            characters) or real Regexp.
            MSG
            UI.deprecation(msg)
            @warning_printed = true
          end

          new_regexp = Regexp.new(pattern).inspect
          UI.info "\"#{pattern}\" will be converted to #{new_regexp}\n"
        end
      end
    end
  end
end
