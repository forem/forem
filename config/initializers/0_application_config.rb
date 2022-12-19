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
      ENV[key]
    else
      Rails.logger.debug { "Unset ENV variable: #{key}." }
      nil
    end
  end

  def self.app_domain_no_port
    app_domain = self["APP_DOMAIN"]
    return unless app_domain

    app_domain.match(URI_REGEXP)[:host]
  end
end
