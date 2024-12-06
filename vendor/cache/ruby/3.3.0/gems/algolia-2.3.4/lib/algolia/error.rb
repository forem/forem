module Algolia
  # Base exception class for errors thrown by the Algolia
  # client library. AlgoliaError will be raised by any
  # network operation if Algolia.init() has not been called.
  # Exception ... why? A:http://www.skorks.com/2009/09/ruby-exceptions-and-exception-handling/
  #
  class AlgoliaError < StandardError
  end

  # Used when hosts are unreachable
  #
  class AlgoliaUnreachableHostError < AlgoliaError
  end

  # An exception class raised when the REST API returns an error.
  # The error code and message will be parsed out of the HTTP response,
  # which is also included in the response attribute.
  #
  class AlgoliaHttpError < AlgoliaError
    attr_accessor :code, :message

    def initialize(code, message)
      self.code    = code
      self.message = message
      super("#{self.code}: #{self.message}")
    end
  end
end
