# frozen_string_literal: true

module Ferrum
  class Network
    class AuthRequest
      attr_accessor :request_id, :frame_id, :resource_type

      def initialize(page, params)
        @page = page
        @params = params
        @request_id = params["requestId"]
        @frame_id = params["frameId"]
        @resource_type = params["resourceType"]
        @request = params["request"]
      end

      def navigation_request?
        @params["isNavigationRequest"]
      end

      def auth_challenge?(source)
        @params.dig("authChallenge", "source")&.downcase&.to_s == source.to_s
      end

      def match?(regexp)
        !!url.match(regexp)
      end

      def continue(**options)
        options = options.merge(requestId: request_id)
        @page.command("Fetch.continueWithAuth", **options)
      end

      def abort
        @page.command("Fetch.failRequest", requestId: request_id, errorReason: "BlockedByClient")
      end

      def url
        @request["url"]
      end

      def method
        @request["method"]
      end

      def headers
        @request["headers"]
      end

      def initial_priority
        @request["initialPriority"]
      end

      def referrer_policy
        @request["referrerPolicy"]
      end

      def inspect
        "#<#{self.class} " \
          "@request_id=#{@request_id.inspect} " \
          "@frame_id=#{@frame_id.inspect} " \
          "@resource_type=#{@resource_type.inspect} " \
          "@request=#{@request.inspect}>"
      end
    end
  end
end
