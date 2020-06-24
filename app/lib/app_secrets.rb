class AppSecrets
  def self.[](key)
    result = Vault.kv(namespace).read(key)&.data&.fetch(:value) if ApplicationConfig["VAULT_TOKEN"].present?
    result ||= ApplicationConfig[key]

    result
  rescue Vault::VaultError
    ApplicationConfig[key]
  end

  def self.[]=(key, value)
    Vault.kv(namespace).write(key, value: value)
  end

  def self.namespace
    ENV["VAULT_SECRET_NAMESPACE"]
  end
  private_class_method :namespace
end
