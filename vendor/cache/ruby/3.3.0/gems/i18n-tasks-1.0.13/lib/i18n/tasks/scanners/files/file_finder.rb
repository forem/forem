# frozen_string_literal: true

module I18n::Tasks::Scanners::Files
  # Finds the files in the specified search paths with support for exclusion / inclusion patterns.
  #
  # @since 0.9.0
  class FileFinder
    include I18n::Tasks::Logging

    # @param paths [Array<String>] {Find.find}-compatible paths to traverse,
    #     absolute or relative to the working directory.
    # @param only [Array<String>, nil] {File.fnmatch}-compatible patterns files to include.
    #     Files not matching any of the inclusion patterns will be excluded.
    # @param exclude [Arry<String>] {File.fnmatch}-compatible patterns of files to exclude.
    #     Files matching any of the exclusion patterns will be excluded even if they match an inclusion pattern.
    def initialize(paths: ['.'], only: nil, exclude: [])
      fail 'paths argument is required' if paths.nil?

      @paths   = paths
      @include = only
      @exclude = exclude || []
    end

    # Traverse the paths and yield the matching ones.
    #
    # @yield [path]
    # @yieldparam path [String] the path of the found file.
    # @return [Array<of block results>]
    def traverse_files(&block)
      find_files.map(&block)
    end

    # @return [Array<String>] found files
    def find_files # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      results = []
      paths = @paths.select { |p| File.exist?(p) }
      log_warn "None of the search.paths exist #{@paths.inspect}" if paths.empty?
      Find.find(*paths) do |path|
        is_dir   = File.directory?(path)
        hidden   = File.basename(path).start_with?('.') && !%w[. ./].include?(path)
        not_incl = @include && !path_fnmatch_any?(path, @include)
        excl     = path_fnmatch_any?(path, @exclude)
        if is_dir || hidden || not_incl || excl
          Find.prune if is_dir && (hidden || excl)
        else
          results << path
        end
      end
      results
    end

    private

    # @param path [String]
    # @param globs [Array<String>]
    # @return [Boolean]
    def path_fnmatch_any?(path, globs)
      globs.any? { |glob| File.fnmatch(glob, path) }
    end
  end
end
