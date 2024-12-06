# frozen_string_literal: true

module Ferrum
  class Network
    class Exchange
      # ID of the request.
      #
      # @return String
      attr_reader :id

      # The intercepted request.
      #
      # @return [InterceptedRequest, nil]
      attr_accessor :intercepted_request

      # The request object.
      #
      # @return [Request, nil]
      attr_accessor :request

      # The response object.
      #
      # @return [Response, nil]
      attr_accessor :response

      # The error object.
      #
      # @return [Error, nil]
      attr_accessor :error

      #
      # Initializes the network exchange.
      #
      # @param [Page] page
      #
      # @param [String] id
      #
      def initialize(page, id)
        @id = id
        @page = page
        @intercepted_request = nil
        @request = @response = @error = nil
      end

      #
      # Determines if the network exchange was caused by a page navigation
      # event.
      #
      # @param [String] frame_id
      #
      # @return [Boolean]
      #
      def navigation_request?(frame_id)
        request&.type?(:document) && request&.frame_id == frame_id
      end

      #
      # Determines if the network exchange has a request.
      #
      # @return [Boolean]
      #
      def blank?
        !request
      end

      #
      # Determines if the request was intercepted and blocked.
      #
      # @return [Boolean]
      #
      def blocked?
        intercepted? && intercepted_request.status?(:aborted)
      end

      #
      # Determines if the request was blocked, a response was returned, or if an
      # error occurred.
      #
      # @return [Boolean]
      #
      def finished?
        blocked? || response&.loaded? || !error.nil?
      end

      #
      # Determines if the network exchange is still not finished.
      #
      # @return [Boolean]
      #
      def pending?
        !finished?
      end

      #
      # Determines if the exchange's request was intercepted.
      #
      # @return [Boolean]
      #
      def intercepted?
        !intercepted_request.nil?
      end

      #
      # Determines if the exchange is XHR.
      #
      # @return [Boolean]
      #
      def xhr?
        !!request&.xhr?
      end

      #
      # Determines if the exchange is a redirect.
      #
      # @return [Boolean]
      #
      def redirect?
        response&.redirect?
      end

      #
      # Returns request's URL.
      #
      # @return [String, nil]
      #
      def url
        request&.url
      end

      #
      # Converts the network exchange into a request, response, and error tuple.
      #
      # @return [Array]
      #
      def to_a
        [request, response, error]
      end

      #
      # Inspects the network exchange.
      #
      # @return [String]
      #
      def inspect
        "#<#{self.class} " \
          "@id=#{@id.inspect} " \
          "@intercepted_request=#{@intercepted_request.inspect} " \
          "@request=#{@request.inspect} " \
          "@response=#{@response.inspect} " \
          "@error=#{@error.inspect}>"
      end
    end
  end
end
