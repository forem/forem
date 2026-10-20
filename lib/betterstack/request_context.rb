require "logtail"

module Betterstack
  # Adds the request (host, method, path, client IP, request id) to every Better Stack line logged
  # during it. Replaces logtail-rack's HTTPContext, which config.app_middleware puts below
  # ActionDispatch::DebugExceptions: its context is gone by the time Rails logs an unhandled exception.
  # Only loaded when BETTERSTACK_SOURCE_TOKEN is set (see config/initializers/betterstack.rb).
  class RequestContext
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      context = Logtail::Contexts::HTTP.new(
        host: request.host,
        method: request.request_method,
        path: request.path,
        # Same client IP as the rest of Forem: Fastly's header, else Rails' remote_ip.
        remote_addr: (env["HTTP_FASTLY_CLIENT_IP"] || request.remote_ip).to_s,
        request_id: request.request_id,
      )
      Logtail::CurrentContext.with(context.to_hash) { @app.call(env) }
    end
  end
end
