# frozen_string_literal: true

module Ferrum
  class Network
    #
    # Represents a [Network.Response](https://chromedevtools.github.io/devtools-protocol/1-3/Network/#type-Response)
    # object.
    #
    class Response
      # The response body size.
      #
      # @return [Integer, nil]
      attr_reader :body_size

      # The parsed JSON attributes for the [Network.Response](https://chromedevtools.github.io/devtools-protocol/1-3/Network/#type-Response)
      # object.
      #
      # @return [Hash{String => Object}]
      attr_reader :params

      # The response is fully loaded by the browser.
      #
      # @return [Boolean]
      attr_writer :loaded

      #
      # Initializes the responses object.
      #
      # @param [Page] page
      #   The page associated with the network response.
      #
      # @param [Hash{String => Object}] params
      #   The parsed JSON attributes for the [Network.Response](https://chromedevtools.github.io/devtools-protocol/1-3/Network/#type-Response)
      #
      def initialize(page, params)
        @page = page
        @params = params
        @response = params["response"] || params["redirectResponse"]
      end

      #
      # The request ID associated with the response.
      #
      # @return [String]
      #
      def id
        @params["requestId"]
      end

      #
      # The URL of the response.
      #
      # @return [String]
      #
      def url
        @response["url"]
      end

      #
      # The HTTP status of the response.
      #
      # @return [Integer]
      #
      def status
        @response["status"]
      end

      #
      # The HTTP status text.
      #
      # @return [String]
      #
      def status_text
        @response["statusText"]
      end

      #
      # The headers of the response.
      #
      # @return [Hash{String => String}]
      #
      def headers
        @response["headers"]
      end

      #
      # The total size in bytes of the response.
      #
      # @return [Integer]
      #
      def headers_size
        @response["encodedDataLength"]
      end

      #
      # The resource type of the response.
      #
      # @return [String]
      #
      def type
        @params["type"]
      end

      #
      # The `Content-Type` header value of the response.
      #
      # @return [String, nil]
      #
      def content_type
        @content_type ||= headers.find { |k, _| k.downcase == "content-type" }&.last&.sub(/;.*\z/, "")
      end

      # See https://crbug.com/883475
      # Sometimes we never get the Network.responseReceived event.
      # See https://crbug.com/764946
      # `Network.loadingFinished` encodedDataLength contains both body and
      # headers sizes received by wire.
      def body_size=(size)
        @body_size = size - headers_size
      end

      #
      # The response body.
      #
      # @return [String]
      #
      def body
        @body ||= begin
          body, encoded = @page.command("Network.getResponseBody", requestId: id)
                               .values_at("body", "base64Encoded")
          encoded ? Base64.decode64(body) : body
        end
      end

      #
      # @return [Boolean]
      #
      def main?
        @page.network.response == self
      end

      # The response is fully loaded by the browser or not.
      #
      # @return [Boolean]
      def loaded?
        @loaded
      end

      # Whether the response is a redirect.
      #
      # @return [Boolean]
      def redirect?
        params.key?("redirectResponse")
      end

      #
      # Compares the response's ID to another response's ID.
      #
      # @return [Boolean]
      #   Indicates whether the response has the same ID as the other response
      #   object.
      #
      def ==(other)
        id == other.id
      end

      #
      # Inspects the response object.
      #
      # @return [String]
      #
      def inspect
        %(#<#{self.class} @params=#{@params.inspect} @response=#{@response.inspect}>)
      end

      alias to_h params
    end
  end
end
