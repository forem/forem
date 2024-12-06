# frozen_string_literals: true

module Lumberjack
  class Device
    # This is a log device that appends entries to a file and rolls the file when it reaches a specified
    # size threshold. When a file is rolled, it will have an number extension appended to the file name.
    # For example, if the log file is named production.log, the first time it is rolled it will be renamed
    # production.log.1, then production.log.2, etc.
    class SizeRollingLogFile < RollingLogFile
      attr_reader :max_size

      # Create an new log device to the specified file. The maximum size of the log file is specified with
      # the :max_size option. The unit can also be specified: "32K", "100M", "2G" are all valid.
      def initialize(path, options = {})
        @manual = options[:manual]
        @max_size = options[:max_size]
        if @max_size.is_a?(String)
          if @max_size =~ /^(\d+(\.\d+)?)([KMG])?$/i
            @max_size = $~[1].to_f
            units = $~[3].to_s.upcase
            case units
            when "K"
              @max_size *= 1024
            when "M"
              @max_size *= 1024**2
            when "G"
              @max_size *= 1024**3
            end
            @max_size = @max_size.round
          else
            raise ArgumentError.new("illegal value for :max_size (#{@max_size})")
          end
        end

        super
      end

      def archive_file_suffix
        next_archive_number.to_s
      end

      def roll_file?
        @manual || stream.stat.size > @max_size
      rescue SystemCallError
        false
      end

      protected

      # Calculate the next archive file name extension.
      def next_archive_number # :nodoc:
        max = 0
        Dir.glob("#{path}.*").each do |filename|
          if /\.\d+\z/ =~ filename
            suffix = filename.split(".").last.to_i
            max = suffix if suffix > max
          end
        end
        max + 1
      end
    end
  end
end
