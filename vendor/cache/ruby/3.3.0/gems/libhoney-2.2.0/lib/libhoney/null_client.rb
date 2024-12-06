require 'libhoney/client'
require 'libhoney/null_transmission'

module Libhoney
  # A no-op client that silently drops events. Does not send events to
  # Honeycomb, or to anywhere else for that matter.
  #
  # This class is intended as a fallback for callers that wanted to instantiate
  # a regular Client but had insufficient config to do so (e.g. missing
  # writekey).
  #
  # @api private
  class NullClient < Client
    def initialize(*args, **kwargs)
      super(*args,
            transmission: NullTransmissionClient.new,
            **kwargs)
    end
  end
end
