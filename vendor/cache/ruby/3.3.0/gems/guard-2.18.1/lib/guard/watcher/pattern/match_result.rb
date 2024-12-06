module Guard
  class Watcher
    class Pattern
      class MatchResult
        def initialize(match_result, original_value)
          @match_result = match_result
          @original_value = original_value
        end

        def [](index)
          return @match_result[index] if index.is_a?(Symbol)
          return @original_value if index.zero?
          @match_result.to_a[index]
        end
      end
    end
  end
end
