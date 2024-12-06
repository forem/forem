require_relative "simple_path"

module Guard
  class Watcher
    class Pattern
      class PathnamePath < SimplePath
        protected

        def normalize(string_or_pathname)
          Pathname.new(string_or_pathname).cleanpath
        end
      end
    end
  end
end
