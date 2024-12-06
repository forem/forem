# frozen_string_literals: true

require "fileutils"

module Lumberjack
  class Device
    # This is a logging device that appends log entries to a file.
    class LogFile < Writer
      EXTERNAL_ENCODING = "ascii-8bit"

      # The absolute path of the file being logged to.
      attr_reader :path

      # Create a logger to the file at +path+. Options are passed through to the Writer constructor.
      #
      # @param [String, Pathname] path The path to the log file.
      # @param [Hash] options The options for the device.
      def initialize(path, options = {})
        @path = File.expand_path(path)
        FileUtils.mkdir_p(File.dirname(@path))
        super(file_stream, options)
      end

      # Reopen the log file.
      #
      # @param [Object] logdev not used
      # @return [void]
      def reopen(logdev = nil)
        close
        @stream = file_stream
      end

      private

      def file_stream
        File.new(@path, "a", encoding: EXTERNAL_ENCODING)
      end
    end
  end
end
