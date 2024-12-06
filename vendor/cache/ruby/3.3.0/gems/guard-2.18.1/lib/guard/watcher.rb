require "guard/config"
require "guard/deprecated/watcher" unless Guard::Config.new.strict?

require "guard/ui"
require "guard/watcher/pattern"

module Guard
  # The watcher defines a RegExp that will be matched against file system
  # modifications.
  # When a watcher matches a change, an optional action block is executed to
  # enable processing the file system change result.
  #
  class Watcher
    Deprecated::Watcher.add_deprecated(self) unless Config.new.strict?
    attr_accessor :pattern, :action

    # Initializes a file watcher.
    #
    # @param [String, Regexp] pattern the pattern to be watched by the Guard
    #   plugin
    # @param [Block] action the action to execute before passing the result to
    #   the Guard plugin
    #
    def initialize(pattern, action = nil)
      @action = action
      @pattern = Pattern.create(pattern)
    end

    # Compare with other watcher
    # @param other [Guard::Watcher] other watcher for comparing
    # @return [true, false] equal or not
    def ==(other)
      action == other.action && pattern == other.pattern
    end

    # Finds the files that matches a Guard plugin.
    #
    # @param [Guard::Plugin] guard the Guard plugin which watchers are used
    # @param [Array<String>] files the changed files
    # @return [Array<Object>] the matched watcher response
    #
    def self.match_files(guard, files)
      return [] if files.empty?

      files.inject([]) do |paths, file|
        guard.watchers.each do |watcher|
          matches = watcher.match(file)
          next(paths) unless matches

          if watcher.action
            result = watcher.call_action(matches)
            if guard.options[:any_return]
              paths << result
            elsif result.respond_to?(:empty?) && !result.empty?
              paths << Array(result)
            else
              next(paths)
            end
          else
            paths << matches[0]
          end

          break if guard.options[:first_match]
        end

        guard.options[:any_return] ? paths : paths.flatten.map(&:to_s)
      end
    end

    def match(string_or_pathname)
      m = pattern.match(string_or_pathname)
      m.nil? ? nil : Pattern::MatchResult.new(m, string_or_pathname)
    end

    # Executes a watcher action.
    #
    # @param [String, MatchData] matches the matched path or the match from the
    #   Regex
    # @return [String] the final paths
    #
    def call_action(matches)
      @action.arity > 0 ? @action.call(matches) : @action.call
    rescue => ex
      UI.error "Problem with watch action!\n#{ex.message}"
      UI.error ex.backtrace.join("\n")
    end
  end
end
