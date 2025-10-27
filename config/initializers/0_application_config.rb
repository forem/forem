# NOTE: We need to ignore this warning early during app startup.
# 1. `parser` is a transitive dependency (`erb_lint` -> `better_html` -> `parser`)
# 2. The warnings are generated while reading the class body, so we need to ignore
#    them *before* the gem's code is read.
# 3. The warning is intentional, it will always occur when the used point release
#    isn't the most recent. Since our update schedule is somewhat influenced by
#    Fedora release cycles right now, this can occur frequently.
require "warning"
Warning.ignore(%r{parser/current})

class ApplicationConfig
  URI_REGEXP = %r{(?<scheme>https?://)?(?<host>.+?)(?<port>:\d+)?$}

  def self.[](key)
    if ENV.key?(key)
      value = ENV[key]
      # Normalize Redis URLs to be more robust across environments
      if key.start_with?("REDIS_") && value
        value = normalize_redis_url(value)
      end
      value
    else
      Rails.logger.debug { "Unset ENV variable: #{key}." }
      # Provide helpful defaults for Redis in development
      if Rails.env.development? && key.start_with?("REDIS_")
        default = "redis://localhost:6379"
        ENV[key] = default
        default
      else
        nil
      end
    end
  end

  def self.app_domain_no_port
    app_domain = self["APP_DOMAIN"]
    return unless app_domain

    app_domain.match(URI_REGEXP)[:host]
  end

  # Attempts to resolve the host in the provided Redis URL. If resolution fails,
  # falls back to localhost while preserving scheme and port.
  def self.normalize_redis_url(url)
    require "uri"
    require "socket"

    uri = URI.parse(url)
    host = uri.host
    return url unless host

    # Will raise SocketError if the hostname cannot be resolved
    Socket.getaddrinfo(host, nil)
    url
  rescue URI::InvalidURIError, SocketError
    # Replace only the authority component with localhost, preserving scheme and port
    begin
      uri = URI.parse(url)
      uri.host = "localhost"
      uri.to_s
    rescue URI::InvalidURIError
      # As a last resort, return a sane default
      "redis://localhost:6379"
    end
  end
end

# Eagerly normalize Redis-related ENV vars at boot so configs that read ENV directly
# (not via ApplicationConfig) also benefit, e.g., cache store and ActionCable.
begin
  if defined?(Rails) && Rails.env.development?
    %w[REDIS_URL REDIS_SIDEKIQ_URL REDIS_SESSIONS_URL REDIS_RPUSH_URL].each do |var|
      val = ENV.fetch(var, nil)
      if val.present?
        ENV[var] = ApplicationConfig.normalize_redis_url(val)
      else
        ENV[var] ||= "redis://localhost:6379"
      end
    end
  else
    %w[REDIS_URL REDIS_SIDEKIQ_URL REDIS_SESSIONS_URL REDIS_RPUSH_URL].each do |var|
      val = ENV.fetch(var, nil)
      ENV[var] = ApplicationConfig.normalize_redis_url(val) if val.present?
    end
  end
rescue StandardError => e
  Rails.logger.debug { "Redis ENV normalization skipped: #{e.message}" } if defined?(Rails)
end
