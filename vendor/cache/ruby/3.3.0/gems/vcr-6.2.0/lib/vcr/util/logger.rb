module VCR
  # @private
  # Provides log message formatting helper methods.
  class Logger
    def initialize(stream)
      @stream = stream
    end

    def log(message, log_prefix, indentation_level = 0)
      indentation = '  ' * indentation_level
      log_message = indentation + log_prefix + message
      @stream.puts log_message
    end

    def request_summary(request, request_matchers)
      attributes = [request.method, request.uri]
      attributes << request.body.to_s[0, 80].inspect if request_matchers.include?(:body)
      attributes << request.headers.inspect          if request_matchers.include?(:headers)
      "[#{attributes.join(" ")}]"
    end

    def response_summary(response)
      "[#{response.status.code} #{response.body[0, 80].inspect}]"
    end

    # @private
    # A null-object version of the Logger. Used when
    # a `debug_logger` has not been set.
    #
    # @note We used to use a null object for the `debug_logger` itself,
    #       but some users noticed a negative perf impact from having the
    #       logger formatting logic still executing in that case, so we
    #       moved the null object interface up a layer to here.
    module Null
      module_function

      def log(*); end
      def request_summary(*); end
      def response_summary(*); end
    end

    # @private
    # Provides common logger helper methods that simply delegate to
    # the underlying logger object.
    module Mixin
      def log(message, indentation_level = 0)
        VCR.configuration.logger.log(message, log_prefix, indentation_level)
      end

      def request_summary(*args)
        VCR.configuration.logger.request_summary(*args)
      end

      def response_summary(*args)
        VCR.configuration.logger.response_summary(*args)
      end
    end
  end
end
