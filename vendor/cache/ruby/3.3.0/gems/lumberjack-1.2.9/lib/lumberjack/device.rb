# frozen_string_literals: true

module Lumberjack
  # This is an abstract class for logging devices. Subclasses must implement the +write+ method and
  # may implement the +close+ and +flush+ methods if applicable.
  class Device
    require_relative "device/writer"
    require_relative "device/log_file"
    require_relative "device/rolling_log_file"
    require_relative "device/date_rolling_log_file"
    require_relative "device/size_rolling_log_file"
    require_relative "device/multi"
    require_relative "device/null"

    # Subclasses must implement this method to write a LogEntry.
    #
    # @param [Lumberjack::LogEntry] entry The entry to write.
    # @return [void]
    def write(entry)
      raise NotImplementedError
    end

    # Subclasses may implement this method to close the device.
    #
    # @return [void]
    def close
      flush
    end

    # Subclasses may implement this method to reopen the device.
    #
    # @param [Object] logdev The log device to use.
    # @return [void]
    def reopen(logdev = nil)
      flush
    end

    # Subclasses may implement this method to flush any buffers used by the device.
    #
    # @return [void]
    def flush
    end

    # Subclasses may implement this method to get the format for log timestamps.
    #
    # @return [String] The format for log timestamps.
    def datetime_format
    end

    # Subclasses may implement this method to set a format for log timestamps.
    #
    # @param [String] format The format for log timestamps.
    # @return [void]
    def datetime_format=(format)
    end
  end
end
