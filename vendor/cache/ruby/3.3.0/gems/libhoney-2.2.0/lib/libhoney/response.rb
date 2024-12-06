require 'http/response/status'

module Libhoney
  class Response
    # The response status from HTTP calls to a Honeycomb API endpoint.
    #
    # For most of the life of this client, this response object has been
    # a pass-through to the underlying HTTP library's response object.
    # This class in the Libhoney namespace now owns the interface for
    # API responses.
    class Status < HTTP::Response::Status; end

    attr_accessor :duration, :status_code, :metadata, :error

    def initialize(duration: 0,
                   status_code: 0,
                   metadata: nil,
                   error: nil)
      @duration    = duration
      @status_code = Status.new(status_code)
      @metadata    = metadata
      @error       = error
    end
  end
end
