require "logtail"

module Betterstack
  # Adds the request (host, method, path, client IP, request id) and current user id to every
  # Better Stack line logged during it. Replaces logtail-rack's HTTPContext and UserContext, and
  # logtail-rails' SessionContext, which config.app_middleware puts below
  # ActionDispatch::DebugExceptions (so their context is gone by the time Rails logs an unhandled
  # exception) and where UserContext eagerly called env["warden"]&.user before every action
  # (forcing a Redis session read and SELECT "users".* on every request).
  # Only loaded when BETTERSTACK_SOURCE_TOKEN is set (see config/initializers/betterstack.rb).
  class RequestContext
    ENV_THREAD_KEY = :_betterstack_request_env

    module LazyUserContext
      def snapshot
        base = super
        if !base.key?(:user) &&
            (env = Thread.current[ENV_THREAD_KEY]) &&
            (user = RequestContext.user_hash(env))
          base = base.merge(user: user)
        end
        base
      end
    end

    Logtail::CurrentContext.prepend(LazyUserContext) unless Logtail::CurrentContext < LazyUserContext

    # Extracts `{ id: user_id }` from the Rack env without querying PostgreSQL or force-loading an
    # unloaded Redis session.
    def self.user_hash(env)
      return unless env

      id = warden_user_id(env["warden"]) ||
        controller_user_id(env["action_controller.instance"]) ||
        session_user_id(env["rack.session"])
      { id: id } if id
    end

    def self.warden_user_id(warden)
      return unless warden

      user = if warden.instance_variable_defined?(:@users)
               warden.instance_variable_get(:@users)&.[](:user)
             elsif warden.respond_to?(:user)
               warden.user
             end
      user.id if user.respond_to?(:id)
    end
    private_class_method :warden_user_id

    def self.controller_user_id(controller)
      return unless controller

      if controller.instance_variable_defined?(:@current_user)
        current_user = controller.instance_variable_get(:@current_user)
        return current_user.id if current_user.respond_to?(:id) && current_user.id
      end

      return unless controller.instance_variable_defined?(:@validated_session_user_id)

      controller.instance_variable_get(:@validated_session_user_id)
    end
    private_class_method :controller_user_id

    def self.session_user_id(session)
      return unless session && (!session.respond_to?(:loaded?) || session.loaded?)

      key = session["warden.user.user.key"]
      first_element = key.first if key.is_a?(Array)
      first_element.first if first_element.is_a?(Array)
    end
    private_class_method :session_user_id

    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      context = Logtail::Contexts::HTTP.new(
        host: request.host,
        method: request.request_method,
        path: request.path,
        # Same client IP as the rest of Forem: Fastly or Cloudflare's header, else Rails' remote_ip.
        remote_addr: (env["HTTP_FASTLY_CLIENT_IP"] || env["HTTP_CF_CONNECTING_IP"] || request.remote_ip).to_s,
        request_id: request.request_id,
      )
      previous_env = Thread.current[ENV_THREAD_KEY]
      Thread.current[ENV_THREAD_KEY] = env
      Logtail::CurrentContext.with(context.to_hash) { @app.call(env) }
    ensure
      Thread.current[ENV_THREAD_KEY] = previous_env
    end
  end
end
