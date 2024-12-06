module Guard
  class Watcher
    class Pattern
      class SimplePath
        def initialize(string_or_pathname)
          @path = normalize(string_or_pathname)
        end

        def match(string_or_pathname)
          cleaned = normalize(string_or_pathname)
          return nil unless @path == cleaned
          [cleaned]
        end

        protected

        def normalize(string_or_pathname)
          Pathname.new(string_or_pathname).cleanpath.to_s
        end
      end
    end
  end
end
