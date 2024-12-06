# frozen_string_literal: true

module Ferrum
  class Error               < StandardError; end
  class NoSuchPageError     < Error; end
  class NoSuchTargetError   < Error; end
  class NotImplementedError < Error; end
  class BinaryNotFoundError < Error; end
  class EmptyPathError < Error; end

  class StatusError < Error
    def initialize(url, message = nil)
      super(message || "Request to #{url} failed to reach server, check DNS and server status")
    end
  end

  class PendingConnectionsError < StatusError
    attr_reader :pendings

    def initialize(url, pendings = [])
      @pendings = pendings

      message = "Request to #{url} reached server, but there are still pending connections: #{pendings.join(', ')}"

      super(url, message)
    end
  end

  class TimeoutError < Error
    def message
      "Timed out waiting for response. It's possible that this happened " \
        "because something took a very long time (for example a page load " \
        "was slow). If so, setting the :timeout option to a higher value might " \
        "help."
    end
  end

  class ScriptTimeoutError < Error
    def message
      "Timed out waiting for evaluated script to return a value"
    end
  end

  class ProcessTimeoutError < Error
    attr_reader :output

    def initialize(timeout, output)
      @output = output
      super("Browser did not produce websocket url within #{timeout} seconds, try to increase `:process_timeout`. See https://github.com/rubycdp/ferrum#customization")
    end
  end

  class DeadBrowserError < Error
    def initialize(message = "Browser is dead or given window is closed")
      super
    end
  end

  class NodeMovingError < Error
    def initialize(node, prev, current)
      @node = node
      @prev = prev
      @current = current
      super(message)
    end

    def message
      "#{@node.inspect} that you're trying to click is moving, hence " \
        "we cannot. Previously it was at #{@prev.inspect} but now at " \
        "#{@current.inspect}."
    end
  end

  class CoordinatesNotFoundError < Error
    def initialize(message = "Could not compute content quads")
      super
    end
  end

  class BrowserError < Error
    attr_reader :response

    def initialize(response)
      @response = response
      super(response["message"])
    end

    def code
      response["code"]
    end

    def data
      response["data"]
    end
  end

  class NodeNotFoundError < BrowserError; end

  class NoExecutionContextError < BrowserError
    def initialize(response = nil)
      response ||= { "message" => "There's no context available" }
      super(response)
    end
  end

  class JavaScriptError < BrowserError
    attr_reader :class_name, :message, :stack_trace

    def initialize(response, stack_trace = nil)
      @class_name, @message = response.values_at("className", "description")
      @stack_trace = stack_trace
      super(response.merge("message" => @message))
    end
  end
end
