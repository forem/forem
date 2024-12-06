# frozen_string_literals: true

module Lumberjack
  class Device
    # This is a logging device that forward log entries to multiple other devices.
    class Multi < Device
      # @param [Array<Lumberjack::Device>] devices The devices to write to.
      def initialize(*devices)
        @devices = devices.flatten
      end

      def write(entry)
        @devices.each do |device|
          device.write(entry)
        end
      end

      def flush
        @devices.each do |device|
          device.flush
        end
      end

      def close
        @devices.each do |device|
          device.close
        end
      end

      def reopen(logdev = nil)
        @devices.each do |device|
          device.reopen(logdev = nil)
        end
      end

      def datetime_format
        @devices.detect(&:datetime_format).datetime_format
      end

      def datetime_format=(format)
        @devices.each do |device|
          device.datetime_format = format
        end
      end
    end
  end
end
