require 'json'
require 'libhoney/cleaner'

module Libhoney
  # For debugging use: a mock version of TransmissionClient that simply prints
  # events to stderr or a file for inspection (and does not send them to
  # Honeycomb, or perform any network activity).
  #
  # @note This class is intended for use in development, for example if you want
  #       to verify what events your instrumented code is sending. Use in
  #       production is not recommended.
  class LogTransmissionClient
    include Cleaner

    def initialize(output:, verbose: false)
      @output  = output
      @verbose = verbose
    end

    # Prints an event
    def add(event)
      if @verbose
        metadata = "Honeycomb dataset '#{event.dataset}' | #{event.timestamp.iso8601}"
        metadata << " (sample rate: #{event.sample_rate})" if event.sample_rate != 1
        @output.print("#{metadata} | ")
      end
      clean_data(event.data).tap do |data|
        @output.puts(data.to_json)
      end
    end

    # Flushes the output (but does not close it)
    def close(_drain)
      @output.flush
    end
  end
end
