module Guard
  class RSpec < Plugin
    module Inspectors
      class BaseInspector
        attr_accessor :options, :spec_paths

        def initialize(options = {})
          @options = options
          @spec_paths = @options[:spec_paths]
          @chdir = @options[:chdir]
        end

        def paths(_paths)
          raise NotImplementedError
        end

        def failed(_locations)
          raise NotImplementedError
        end

        def reload
          raise NotImplementedError
        end

        private

        # Leave only spec/feature files from spec_paths, remove others
        def _clean(paths)
          paths.uniq!
          paths.compact!
          spec_dirs = _select_only_spec_dirs(paths)
          spec_files = _select_only_spec_files(paths)
          (spec_dirs + spec_files).uniq
        end

        def _select_only_spec_dirs(paths)
          chdir_paths = _spec_paths_with_chdir
          paths.select do |path|
            File.directory?(path) || chdir_paths.include?(path)
          end
        end

        def _select_only_spec_files(paths)
          spec_files = _collect_files("*[_.]spec.rb")
          feature_files = _collect_files("*.feature")
          files = (spec_files + feature_files).flatten

          paths.select do |path|
            (files & [@chdir ? File.join(@chdir, path) : path]).any?
          end
        end

        def _spec_paths_with_chdir
          _paths_with_chdir(spec_paths, @chdir)
        end

        def _collect_files(pattern)
          base_paths = _spec_paths_with_chdir
          base_paths.map do |path|
            # TODO: not tested properly
            Dir[File.join(path, "**{,/*/**}", pattern)]
          end
        end

        def _paths_with_chdir(paths, chdir)
          paths.map do |path|
            chdir ? File.join(chdir, path) : path
          end
        end
      end
    end
  end
end
