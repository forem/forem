Vault.configure do |config|
  # The address of the Vault server, also read as
  config.address = ENV.fetch("VAULT_ADDR", "http://127.0.0.1:8200")

  # The policy token to authenticate with Vault
  # Each app will get its own policy https://learn.hashicorp.com/vault/getting-started/policies#overview
  # Each policy comes with its own token to give the app access to ONLY its secrets
  config.token = ENV.fetch("VAULT_TOKEN", nil)

  # Mimic Paths for communities

  # Optional - if using the Namespace enterprise feature
  # config.namespace = ENV["VAULT_NAMESPACE"]

  # Proxy connection information, also read as ENV["VAULT_PROXY_(thing)"]
  # config.proxy_address  = "..."
  # config.proxy_port     = "..."
  # config.proxy_username = "..."
  # config.proxy_password = "..."

  # Custom SSL PEM, also read as ENV["VAULT_SSL_CERT"]
  # config.ssl_pem_file = "/path/on/disk.pem"

  # As an alternative to a pem file, you can provide the raw PEM string, also read in the following order of preference:
  # ENV["VAULT_SSL_PEM_CONTENTS_BASE64"] then ENV["VAULT_SSL_PEM_CONTENTS"]
  # config.ssl_pem_contents = "-----BEGIN ENCRYPTED..."

  # Use SSL verification, also read as ENV["VAULT_SSL_VERIFY"]
  config.ssl_verify = ENV.fetch("VAULT_SSL_VERIFY", true)

  # Timeout the connection after a certain amount of time (seconds), also read
  # as ENV["VAULT_TIMEOUT"]
  config.timeout = 30

  # It is also possible to have finer-grained controls over the timeouts, these
  # may also be read as environment variables
  config.ssl_timeout  = 5
  config.open_timeout = 5
  config.read_timeout = 30
end
