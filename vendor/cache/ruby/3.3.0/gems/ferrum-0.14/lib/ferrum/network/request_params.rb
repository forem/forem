# frozen_string_literal: true

module Ferrum
  class Network
    #
    # Common methods used by both {Request} and {InterceptedRequest}.
    #
    module RequestParams
      #
      # The URL for the request.
      #
      # @return [String]
      #
      def url
        @request["url"]
      end

      #
      # The URL fragment for the request.
      #
      # @return [String, nil]
      #
      def url_fragment
        @request["urlFragment"]
      end

      #
      # The request method.
      #
      # @return [String]
      #
      def method
        @request["method"]
      end

      #
      # The request headers.
      #
      # @return [Hash{String => String}]
      #
      def headers
        @request["headers"]
      end

      #
      # The optional HTTP `POST` form data.
      #
      # @return [String, nil]
      #   The HTTP `POST` form data.
      #
      def post_data
        @request["postData"]
      end
      alias body post_data
    end
  end
end
