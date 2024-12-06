require 'libhoney/client'
require 'libhoney/log_transmission'

module Libhoney
  # A client that prints events to stderr or a file for inspection. Does not
  # actually send any events to Honeycomb; instead, records events for later
  # inspection.
  #
  # @note This class is intended for use in development, for example if you want
  #       to verify what events your instrumented code is sending. Use in
  #       production is not recommended.
  class LogClient < Client
    def initialize(*args, output: $stderr, verbose: false, **kwargs)
      super(*args,
            transmission: LogTransmissionClient.new(output: output, verbose: verbose),
            **kwargs)
    end
  end
end
