# Docker specific development configuration
if Rails.env.development? && File.file?("/.dockerenv")
  # Using shell tools so we don't need to require Socket and IPAddr
  host_ip = `/sbin/ip route|awk '/default/ { print $3 }'`.strip
  logger = Logger.new(STDOUT)
  logger.info "Whitelisting #{host_ip} for BetterErrors and Web Console"

  if defined?(BetterErrors::Middleware)
    BetterErrors::Middleware.allow_ip!(host_ip)
  end

  Rails.application.config.web_console.whitelisted_ips << host_ip
end
