module Middlewares
  class RestoreOriginalHost
    VALID_HOST_REGEXP = /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}\z/i

    def initialize(app)
      @app = app
    end

    def call(env)
      # Fastly-Orig-Host is set by Fastly to the client's original Host header.
      original_host = env["HTTP_FASTLY_ORIG_HOST"].presence

      # Allow X-Forwarded-Host as well as Fastly-Orig-Host in all environments.
      # This is secure because Fastly is configured to unconditionally overwrite X-Forwarded-Host at the edge.
      original_host ||= env["HTTP_X_FORWARDED_HOST"]&.split(",")&.first&.strip.presence

      if original_host && valid_host?(original_host)
        env["HTTP_HOST"] = original_host
      end

      @app.call(env)
    end

    private

    def valid_host?(host)
      host_without_port = host.split(":").first
      host_without_port.match?(VALID_HOST_REGEXP) || host_without_port == "localhost"
    end
  end
end
