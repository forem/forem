# frozen_string_literal: true

module Ferrum
  class Network
    class Error
      attr_writer :canceled
      attr_reader :time, :timestamp
      attr_accessor :id, :url, :type, :error_text, :monotonic_time, :description

      def canceled?
        @canceled
      end

      def timestamp=(value)
        @timestamp = value
        @time = Time.strptime((value / 1000).to_s, "%s")
      end
    end
  end
end
