# frozen_string_literal: true

require "honeycomb/integrations/active_support"
require "honeycomb/integrations/rack"
require "honeycomb/integrations/warden"

module Honeycomb
  # Rails specific methods for building middleware
  module Rails
    def add_package_information(env)
      yield "meta.package", "rails"
      yield "meta.package_version", ::Rails::VERSION::STRING

      request = ::ActionDispatch::Request.new(env)

      yield "request.controller", request.path_parameters[:controller]
      yield "request.action", request.path_parameters[:action]
      yield "request.route", route_for(request)
    end

    private

    def route_for(request)
      router = router_for(request)
      routing = routing_for(request)

      return unless router && routing

      router.recognize(routing) do |route, _|
        return "#{request.method} #{route.path.spec}"
      end
    end

    # Broadly compatible way of getting the ActionDispatch::Routing::RouteSet.
    #
    # While we'd like to just use ActionDispatch::Request#routes, that method
    # was only added circa Rails 5. To support Rails 4, we have to use direct
    # Rack env access.
    #
    # @see https://github.com/rails/rails/commit/87a75910640b83a677099198ccb3317d9850c204
    def router_for(request)
      routes = request.env["action_dispatch.routes"]
      routes.router if routes.respond_to?(:router)
    end

    # Constructs a simplified ActionDispatch::Request with the original route.
    #
    # This is based on ActionDispatch::Routing::RouteSet#recognize_path, which
    # reconstructs an ActionDispatch::Request using a given HTTP method + path
    # by making a mock Rack environment. Here, instead of taking the method +
    # path from input parameters, we use the original values from the actual
    # incoming request (prior to any mangling that may have been done by
    # middleware).
    #
    # The resulting ActionDispatch::Request instance is suitable for passing to
    # ActionDispatch::Journey::Router#recognize to get the original Rails
    # routing information corresponding to the incoming request.
    #
    # @param request [ActionDispatch::Request]
    #   the actual incoming Rails request
    #
    # @return [ActionDispatch::Request]
    #   a simplified version of the incoming request that retains the original
    #   routing information, but nothing else (e.g., no HTTP parameters)
    #
    # @return [nil]
    #   if the original request's path is invalid
    #
    # @see https://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-method
    # @see https://api.rubyonrails.org/classes/ActionDispatch/Request.html#method-i-original_fullpath
    # @see https://github.com/rails/rails/blob/2a44ff12c858d296797963f7aa97abfa0c840a15/actionpack/lib/action_dispatch/journey/router/utils.rb#L7-L27
    # @see https://github.com/rails/rails/blob/2a44ff12c858d296797963f7aa97abfa0c840a15/actionpack/lib/action_dispatch/routing/route_set.rb#L846-L859
    def routing_for(request)
      verb = request.method
      path = request.original_fullpath
      path = normalize(path) unless path =~ %r{://}
      env = ::Rack::MockRequest.env_for(path, method: verb)
      ::ActionDispatch::Request.new(env)
    rescue URI::InvalidURIError
      nil
    end

    def normalize(path)
      ::ActionDispatch::Journey::Router::Utils.normalize_path(path)
    end

    # Rails middleware
    class Middleware
      include Rack
      include Warden
      include Rails

      def call_with_hook(env, span, &_add_field)
        super
      rescue StandardError => e
        wrapped = ActionDispatch::ExceptionWrapper.new(nil, e)

        span.add_field "response.status_code", wrapped.status_code

        raise e
      end
    end
  end
end
