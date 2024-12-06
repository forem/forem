module Flipper
  module UI
    # All flipper ui errors inherit from this.
    Error = Class.new(StandardError)

    # Raised when a request method (get, post, etc.) is called for an action
    # that does not know how to handle it.
    RequestMethodNotSupported = Class.new(Error)
  end
end
