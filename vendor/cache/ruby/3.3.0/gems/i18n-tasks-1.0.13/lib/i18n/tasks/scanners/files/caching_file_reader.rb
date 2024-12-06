# frozen_string_literal: true

require 'i18n/tasks/concurrent/cache'
require 'i18n/tasks/scanners/files/file_reader'

module I18n::Tasks::Scanners::Files
  # Reads the files in 'rb' mode and UTF-8 encoding.
  # Wraps a {FileReader} and caches the results.
  #
  # @note This class is thread-safe. All methods are cached.
  # @since 0.9.0
  class CachingFileReader < FileReader
    def initialize
      super
      @cache = ::I18n::Tasks::Concurrent::Cache.new
    end

    # Return the contents of the file at the given path.
    # The file is read in the 'rb' mode and UTF-8 encoding.
    #
    # @param (see FileReader#read_file)
    # @return (see FileReader#read_file)
    # @note This method is cached, it will only access the filesystem on the first invocation.
    def read_file(path)
      @cache.fetch(File.expand_path(path)) { super }
    end
  end
end
