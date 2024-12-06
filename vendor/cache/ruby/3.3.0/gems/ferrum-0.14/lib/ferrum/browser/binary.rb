# frozen_string_literal: true

module Ferrum
  class Browser
    module Binary
      module_function

      def find(commands)
        enum(commands).first
      end

      def all(commands)
        enum(commands).force
      end

      def enum(commands)
        paths, exts = prepare_paths
        cmds = Array(commands).product(paths, exts)
        lazy_find(cmds)
      end

      def prepare_paths
        exts = (ENV.key?("PATHEXT") ? ENV.fetch("PATHEXT").split(";") : []) << ""
        paths = ENV["PATH"].split(File::PATH_SEPARATOR)
        raise EmptyPathError if paths.empty?

        [paths, exts]
      end

      # rubocop:disable Style/CollectionCompact
      def lazy_find(cmds)
        cmds.lazy.map do |cmd, path, ext|
          absolute_path = File.absolute_path(cmd)
          is_absolute_path = absolute_path == cmd
          cmd = File.expand_path("#{cmd}#{ext}", path) unless is_absolute_path

          next unless File.executable?(cmd)
          next if File.directory?(cmd)

          cmd
        end.reject(&:nil?) # .compact isn't defined on Enumerator::Lazy
      end
      # rubocop:enable Style/CollectionCompact
    end
  end
end
