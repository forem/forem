require "openssl"

config = ActiveSupport::OrderedOptions.new
config.enabled = ENV["DELEGATED_ACCESS_ENABLED"] == "true"

if config.enabled
  required_env = lambda do |name|
    value = ENV.fetch(name)
    raise ArgumentError, "#{name} must not be blank" if value.blank?

    value.dup.freeze
  end

  config.issuer = required_env.call("DELEGATED_ACCESS_ISSUER")
  config.audience = required_env.call("DELEGATED_ACCESS_AUDIENCE")
  config.key_id = required_env.call("DELEGATED_ACCESS_KEY_ID")
  config.client_id = required_env.call("DELEGATED_ACCESS_CLIENT_ID")
  config.identity_provider = required_env.call("DELEGATED_ACCESS_IDENTITY_PROVIDER")
  config.owner_claim = required_env.call("DELEGATED_ACCESS_OWNER_CLAIM")

  public_key = OpenSSL::PKey::RSA.new(required_env.call("DELEGATED_ACCESS_PUBLIC_KEY").gsub('\n', "\n"))
  raise ArgumentError, "DELEGATED_ACCESS_PUBLIC_KEY must not contain a private key" if public_key.private?

  config.public_key = public_key.freeze
end

Rails.application.config.x.delegated_access = config.freeze
