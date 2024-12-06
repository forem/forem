# frozen_string_literal: true

require 'yaml'

module Solargraph
  class Workspace
    # Configuration data for a workspace.
    #
    class Config
      # The maximum number of files that can be added to a workspace.
      # The workspace's .solargraph.yml can override this value.
      MAX_FILES = 5000

      # @return [String]
      attr_reader :directory

      # @return [Hash]
      attr_reader :raw_data

      # @param directory [String]
      def initialize directory = ''
        @directory = directory
        @raw_data = config_data
        included
        excluded
      end

      # An array of files included in the workspace (before calculating excluded files).
      #
      # @return [Array<String>]
      def included
        return [] if directory.empty? || directory == '*'
        @included ||= process_globs(@raw_data['include'])
      end

      # An array of files excluded from the workspace.
      #
      # @return [Array<String>]
      def excluded
        return [] if directory.empty? || directory == '*'
        @excluded ||= process_exclusions(@raw_data['exclude'])
      end

      def allow? filename
        filename.start_with?(directory) && 
          !excluded.include?(filename) &&
          excluded_directories.none? { |d| filename.start_with?(d) }
      end

      # The calculated array of (included - excluded) files in the workspace.
      #
      # @return [Array<String>]
      def calculated
        Solargraph.logger.info "Indexing workspace files in #{directory}" unless @calculated || directory.empty? || directory == '*'
        @calculated ||= included - excluded
      end

      # An array of domains configured for the workspace.
      # A domain is a namespace that the ApiMap should include in the global
      # namespace. It's typically used to identify available DSLs.
      #
      # @return [Array<String>]
      def domains
        raw_data['domains']
      end

      # An array of required paths to add to the workspace.
      #
      # @return [Array<String>]
      def required
        raw_data['require']
      end

      # An array of load paths for required paths.
      #
      # @return [Array<String>]
      def require_paths
        raw_data['require_paths'] || []
      end

      # An array of reporters to use for diagnostics.
      #
      # @return [Array<String>]
      def reporters
        raw_data['reporters']
      end

      # A hash of options supported by the formatter
      #
      # @return [Hash]
      def formatter
        raw_data['formatter']
      end

      # An array of plugins to require.
      #
      # @return [Array<String>]
      def plugins
        raw_data['plugins']
      end

      # The maximum number of files to parse from the workspace.
      #
      # @return [Integer]
      def max_files
        raw_data['max_files']
      end

      private

      # @return [String]
      def global_config_path
        ENV['SOLARGRAPH_GLOBAL_CONFIG'] || 
          File.join(Dir.home, '.config', 'solargraph', 'config.yml')
      end

      # @return [String]
      def workspace_config_path
        return '' if @directory.empty?
        File.join(@directory, '.solargraph.yml')
      end

      # @return [Hash]
      def config_data
        workspace_config = read_config(workspace_config_path)
        global_config = read_config(global_config_path)

        defaults = default_config
        defaults.merge({'exclude' => []}) unless workspace_config.nil?

        defaults
          .merge(global_config || {})
          .merge(workspace_config || {})
      end

      # Read a .solargraph yaml config
      #
      # @param directory [String]
      # @return [Hash, nil]
      def read_config config_path = ''
        return nil if config_path.empty?
        return nil unless File.file?(config_path)
        YAML.safe_load(File.read(config_path))
      end

      # @return [Hash]
      def default_config
        {
          'include' => ['**/*.rb'],
          'exclude' => ['spec/**/*', 'test/**/*', 'vendor/**/*', '.bundle/**/*'],
          'require' => [],
          'domains' => [],
          'reporters' => %w[rubocop require_not_found],
          'formatter' => {
            'rubocop' => {
              'cops' => 'safe',
              'except' => [],
              'only' => [],
              'extra_args' =>[]
            }
          },
          'require_paths' => [],
          'plugins' => [],
          'max_files' => MAX_FILES
        }
      end

      # Get an array of files from the provided globs.
      #
      # @param globs [Array<String>]
      # @return [Array<String>]
      def process_globs globs
        result = globs.flat_map do |glob|
          Dir[File.join directory, glob]
            .map{ |f| f.gsub(/\\/, '/') }
            .select { |f| File.file?(f) }
        end
        result
      end

      # Modify the included files based on excluded directories and get an
      # array of additional files to exclude.
      #
      # @param globs [Array<String>]
      # @return [Array<String>]
      def process_exclusions globs
        remainder = globs.select do |glob|
          if glob_is_directory?(glob)
            exdir = File.join(directory, glob_to_directory(glob))
            included.delete_if { |file| file.start_with?(exdir) }
            false
          else
            true
          end
        end
        process_globs remainder
      end

      # True if the glob translates to a whole directory.
      #
      # @example
      #   glob_is_directory?('path/to/dir')       # => true
      #   glob_is_directory?('path/to/dir/**/*)   # => true
      #   glob_is_directory?('path/to/file.txt')  # => false
      #   glob_is_directory?('path/to/*.txt')     # => false
      #
      # @param glob [String]
      # @return [Boolean]
      def glob_is_directory? glob
        File.directory?(glob) || File.directory?(glob_to_directory(glob))
      end

      # Translate a glob to a base directory if applicable
      #
      # @example
      #   glob_to_directory('path/to/dir/**/*') # => 'path/to/dir'
      #
      # @param glob [String]
      # @return [String]
      def glob_to_directory glob
        glob.gsub(/(\/\*|\/\*\*\/\*\*?)$/, '')
      end

      def excluded_directories
        @raw_data['exclude']
          .select { |g| glob_is_directory?(g) }
          .map { |g| File.join(directory, glob_to_directory(g)) }
      end
    end
  end
end
