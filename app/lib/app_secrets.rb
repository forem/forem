class AppSecrets
  def self.[](key)
    result = Vault.kv(namespace).read(key)&.data&.fetch(:value) if vault_enabled?
    result ||= ApplicationConfig[key]

    result
  rescue Vault::VaultError
    ApplicationConfig[key]
  end

  def self.[]=(key, value)
    Vault.kv(namespace).write(key, value: value)
  end

  def self.vault_enabled?
    ENV["VAULT_TOKEN"].present?
  end

  def self.namespace
    ENV.fetch("VAULT_SECRET_NAMESPACE", nil)
  end
  private_class_method :namespace
end
