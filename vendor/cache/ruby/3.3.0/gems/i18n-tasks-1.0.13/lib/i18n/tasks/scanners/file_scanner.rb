# frozen_string_literal: true

require 'i18n/tasks/scanners/scanner'

module I18n::Tasks::Scanners
  # A base class for a scanner that analyses files.
  #
  # @abstract The child must implement {#scan_file}.
  # @since 0.9.0
  class FileScanner < Scanner
    attr_reader :config

    def initialize(
      config: {},
      file_finder_provider: Files::CachingFileFinderProvider.new,
      file_reader: Files::CachingFileReader.new
    )
      super()
      @config      = config
      @file_reader = file_reader
      @file_finder = file_finder_provider.get(**config.slice(:paths, :only, :exclude))
    end

    # @return (see Scanner#keys)
    def keys
      (traverse_files do |path|
        scan_file(path)
      end.reduce(:+) || []).group_by(&:first).map do |key, keys_occurrences|
        Results::KeyOccurrences.new(key: key, occurrences: keys_occurrences.map(&:second))
      end
    end

    protected

    # Extract all occurrences of translate calls from the file at the given path.
    #
    # @return [Array<[key, Results::KeyOccurrence]>] each occurrence found in the file
    def scan_file(_path)
      fail 'Unimplemented'
    end

    # Read a file. Reads of the same path are cached.
    #
    # @param path [String]
    # @return [String] file contents
    def read_file(path)
      @file_reader.read_file(path)
    end

    # Traverse the paths and yield the matching ones.
    #
    # @note This method is cached, it will only access the filesystem on the first invocation.
    # @param (see FileFinder#traverse_files)
    # @yieldparam (see FileFinder#traverse_files)
    # @return (see FileFinder#traverse_files)
    def traverse_files(&block)
      @file_finder.traverse_files(&block)
    end

    # @note This method is cached, it will only access the filesystem on the first invocation.
    # @return (see FileFinder#find_files)
    def find_files
      @file_finder.find_files
    end
  end
end
