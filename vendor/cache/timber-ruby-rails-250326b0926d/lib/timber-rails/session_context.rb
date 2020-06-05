require "timber/contexts/session"
require "timber-rack/middleware"

module Timber
  module Integrations
    module Rails
      # A Rack middleware that is responsible for adding the Session context
      # {Timber::Contexts::Session}.
      class SessionContext < Timber::Integrations::Rack::Middleware
        def call(env)
          id = get_session_id(env)
          if id
            context = Contexts::Session.new(id: id)
            CurrentContext.add(context.to_hash)
          end
          @app.call(env)
        end

        private
          def get_session_id(env)
            session_key = ::Rails.application.config.session_options[:key]
            request = ::ActionDispatch::Request.new(env)
            extract_from_cookie(request, session_key)
          rescue Exception => e
            nil
          end

          def extract_from_cookie(request, session_key)
            data = request
              .cookie_jar
              .signed_or_encrypted[session_key] || {}
            data["session_id"]
          end
      end
    end
  end
end
