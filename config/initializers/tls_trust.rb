Excon.defaults[:ssl_verify_callback] ||= lambda do |preverified, context|
  preverified && !HTTPClient::SSLConfig.blocked_public_key?(context.current_cert.public_key.public_to_der)
end

Stripe.ca_bundle_path = Excon::DEFAULT_CA_FILE
Stripe.ca_store
