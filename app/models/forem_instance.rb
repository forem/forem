class ForemInstance
  def self.deployed_at
    @deployed_at ||= ApplicationConfig["RELEASE_FOOTPRINT"].presence ||
      ENV["HEROKU_RELEASE_CREATED_AT"].presence ||
      Time.current.to_s
  end

  def self.latest_commit_id
    @latest_commit_id ||= ApplicationConfig["FOREM_BUILD_SHA"].presence || ENV["HEROKU_SLUG_COMMIT"].presence
  end

  def self.email
    ApplicationConfig["DEFAULT_EMAIL"]
  end

  # Return true if we are operating on a local installation, false otherwise
  def self.local?
    Settings::General.app_domain.include?("localhost")
  end

  # Used where we need to keep old DEV features around but don't want to/cannot
  # expose them to other communities.
  def self.dev_to?
    Settings::General.app_domain == "dev.to"
  end

  def self.smtp_enabled?
    (Settings::SMTP.user_name.present? && Settings::SMTP.password.present?) || ENV["SENDGRID_API_KEY"].present?
  end
end
