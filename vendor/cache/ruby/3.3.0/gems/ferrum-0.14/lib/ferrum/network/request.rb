# frozen_string_literal: true

require "ferrum/network/request_params"
require "time"

module Ferrum
  class Network
    #
    # Represents a [Network.Request](https://chromedevtools.github.io/devtools-protocol/1-3/Network/#type-Request)
    # object.
    #
    class Request
      include RequestParams

      #
      # Initializes the request object.
      #
      # @param [Hash{String => Object}] params
      #   The parsed JSON attributes.
      #
      def initialize(params)
        @params = params
        @request = @params["request"]
      end

      #
      # The request ID.
      #
      # @return [String]
      #
      def id
        @params["requestId"]
      end

      #
      # The request resouce type.
      #
      # @return [String]
      #
      def type
        @params["type"]
      end

      #
      # Determines if the request is of the given type.
      #
      # @param [String, Symbol] value
      #   The type value to compare against.
      #
      # @return [Boolean]
      #
      def type?(value)
        type.downcase == value.to_s.downcase
      end

      #
      # Determines if the request is XHR.
      #
      # @return [Boolean]
      #
      def xhr?
        type?("xhr")
      end

      #
      # The frame ID of the request.
      #
      # @return [String]
      #
      def frame_id
        @params["frameId"]
      end

      #
      # The request timestamp.
      #
      # @return [Time]
      #
      def time
        @time ||= Time.strptime(@params["wallTime"].to_s, "%s")
      end

      #
      # Converts the request to a Hash.
      #
      # @return [Hash{String => Object}]
      #   The params of the request.
      #
      def to_h
        @params
      end
    end
  end
end
