class AppSecrets
  SETTABLE_SECRETS = %w[
    SLACK_CHANNEL
    SLACK_DEPLOY_CHANNEL
    SLACK_WEBHOOK_URL
    GITHUB_KEY
    GITHUB_SECRET
    TWITTER_KEY
    TWITTER_SECRET
  ].freeze

  def self.[](key)
    result = Vault.kv(namespace).read(key)&.data&.fetch(:value) if vault_enabled?
    result ||= ApplicationConfig[key]

    result
  rescue Vault::VaultError
    ApplicationConfig[key]
  end

  def self.[]=(key, value)
    write_to_rails_config(key, value)
    Vault.kv(namespace).write(key, value: value)
  end

  def self.vault_enabled?
    ENV["VAULT_TOKEN"].present?
  end

  def write_to_rails_config(key, value)
    # Write to appropriate config after writing to vault.
    # So that the setting is live right away instead of only on reboot
    # For specific values where this is appropriate and safe.

    case key
    when "GITHUB_KEY"
      Devise.omniauth :github, value, self["GITHUB_SECRET"]
    when "GITHUB_SECRET"
      Devise.omniauth :github, self["GITHUB_KEY"], value
    when "TWITTER_KEY"
      Devise.omniauth :twitter, value, self["TWITTER_SECRET"]
    when "TWITTER_SECRET"
      Devise.omniauth :twitter, self["TWITTER_KEY"], value
    end
  end

  def self.namespace
    ENV["VAULT_SECRET_NAMESPACE"]
  end
  private_class_method :namespace
end
