# frozen_string_literal: true

module I18n
  module Tasks
    module Scanners
      module RelativeKeys
        # @param key [String] relative i18n key (starts with a .)
        # @param path [String] path to the file containing the key
        # @param roots [Array<String>] paths to relative roots
        # @param calling_method [#call, Symbol, String, false, nil]
        # @return [String] absolute version of the key
        def absolute_key(key, path, roots: config[:relative_roots],
                         exclude_method_name_paths: config[:relative_exclude_method_name_paths],
                         calling_method: nil)
          return key unless key.start_with?(DOT)
          fail 'roots argument is required' unless roots.present?

          normalized_path = File.expand_path(path)
          (root = path_root(normalized_path, roots)) ||
            fail(CommandError, "Cannot resolve relative key \"#{key}\".\n" \
                               "Set search.relative_roots in config/i18n-tasks.yml (currently #{roots.inspect})")
          normalized_path.sub!(root, '')

          if (exclude_method_name_paths || []).map { |p| expand_path(p) }.include?(root)
            "#{prefix(normalized_path)}#{key}"
          else
            "#{prefix(normalized_path, calling_method: calling_method)}#{key}"
          end
        end

        private

        DOT = '.'

        # Detect the appropriate relative path root
        # @param [String] path /full/path
        # @param [Array<String>] roots array of full paths
        # @return [String] the closest ancestor root for path, with a trailing {File::SEPARATOR}.
        def path_root(path, roots)
          roots.map do |p|
            expand_path(p)
          end.sort.reverse_each.detect do |root|
            path.start_with?(root)
          end
        end

        # Expand a path and add a trailing {File::SEPARATOR}
        # @param [String] path relative path
        # @return [String] absolute path, with a trailing {File::SEPARATOR}.
        def expand_path(path)
          File.expand_path(path) + File::SEPARATOR
        end

        # @param normalized_path [String] path/relative/to/a/root
        # @param calling_method [#call, Symbol, String, false, nil]
        def prefix(normalized_path, calling_method: nil)
          file_key       = normalized_path.gsub(%r{(\.[^/]+)*$}, '').tr(File::SEPARATOR, DOT)
          calling_method = calling_method.call if calling_method.respond_to?(:call)
          if calling_method&.present?
            # Relative keys in mailers have a `_mailer` infix, but relative keys in controllers do not have one:
            "#{file_key.sub(/_controller$/, '')}.#{calling_method}"
          else
            # Remove _ prefix from partials
            file_key.gsub(/\._/, DOT)
          end
        end
      end
    end
  end
end
