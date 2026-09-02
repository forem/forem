require "openssl"

config = Rails.application.config.x.delegated_access
config.enabled = ENV["DELEGATED_ACCESS_ENABLED"] == "true"

if config.enabled
  config.issuer = ENV.fetch("DELEGATED_ACCESS_ISSUER")
  config.audience = ENV.fetch("DELEGATED_ACCESS_AUDIENCE")
  public_key = OpenSSL::PKey::RSA.new(ENV.fetch("DELEGATED_ACCESS_PUBLIC_KEY").gsub('\n', "\n"))
  raise ArgumentError, "DELEGATED_ACCESS_PUBLIC_KEY must not contain a private key" if public_key.private?

  config.public_key = public_key
else
  config.public_key = nil
end
