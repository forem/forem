# frozen_string_literal: true

module I18n::Tasks::Scanners::Files
  # Reads the files in 'rb' mode and UTF-8 encoding.
  #
  # @since 0.9.0
  class FileReader
    # Return the contents of the file at the given path.
    # The file is read in the 'rb' mode and UTF-8 encoding.
    #
    # @param path [String] Path to the file, absolute or relative to the working directory.
    # @return [String] file contents
    def read_file(path)
      result = nil
      File.open(path, 'rb', encoding: 'UTF-8') { |f| result = f.read }
      result
    end
  end
end
