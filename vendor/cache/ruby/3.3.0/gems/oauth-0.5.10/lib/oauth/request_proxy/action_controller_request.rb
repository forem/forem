# frozen_string_literal: true

require "active_support"
require "active_support/version"
require "action_controller"
require "uri"

if Gem::Version.new(ActiveSupport::VERSION::STRING) < Gem::Version.new("3")
  # rails 2.x
  require "action_controller/request"
  unless ActionController::Request::HTTP_METHODS.include?("patch")
    ActionController::Request::HTTP_METHODS << "patch"
    ActionController::Request::HTTP_METHOD_LOOKUP["PATCH"] = :patch
    ActionController::Request::HTTP_METHOD_LOOKUP["patch"] = :patch
  end

elsif Gem::Version.new(ActiveSupport::VERSION::STRING) < Gem::Version.new("4")
  # rails 3.x
  require "action_dispatch/http/request"
  unless ActionDispatch::Request::HTTP_METHODS.include?("patch")
    ActionDispatch::Request::HTTP_METHODS << "patch"
    ActionDispatch::Request::HTTP_METHOD_LOOKUP["PATCH"] = :patch
    ActionDispatch::Request::HTTP_METHOD_LOOKUP["patch"] = :patch
  end

else # rails 4.x and later - already has patch
  require "action_dispatch/http/request"
end

module OAuth
  module RequestProxy
    class ActionControllerRequest < OAuth::RequestProxy::Base
      proxies(defined?(::ActionDispatch::AbstractRequest) ? ::ActionDispatch::AbstractRequest : ::ActionDispatch::Request)

      def method
        request.method.to_s.upcase
      end

      def uri
        request.url
      end

      def parameters
        if options[:clobber_request]
          options[:parameters] || {}
        else
          params = request_params.merge(query_params).merge(header_params)
          params.stringify_keys! if params.respond_to?(:stringify_keys!)
          params.merge(options[:parameters] || {})
        end
      end

      # Override from OAuth::RequestProxy::Base to avoid roundtrip
      # conversion to Hash or Array and thus preserve the original
      # parameter names
      def parameters_for_signature
        params = []
        params << options[:parameters].to_query if options[:parameters]

        unless options[:clobber_request]
          params << header_params.to_query
          params << request.query_string unless query_string_blank?

          params << request.raw_post if raw_post_signature?
        end

        params.
          join("&").split("&").
          reject { |s| s.match(/\A\s*\z/) }.
          map { |p| p.split("=").map { |esc| CGI.unescape(esc) } }.
          reject { |kv| kv[0] == "oauth_signature" }
      end

      def raw_post_signature?
        (request.post? || request.put?) && request.content_type.to_s.downcase.start_with?("application/x-www-form-urlencoded")
      end

      protected

      def query_params
        request.query_parameters
      end

      def request_params
        request.request_parameters
      end
    end
  end
end
