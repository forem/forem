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

  def self.contact_email
    Settings::General.contact_email
  end

  def self.reply_to_email_address
    # Some business logic context:
    # For a Forem Cloud Account, ApplicationConfig["DEFAULT_EMAIL"] will already be set to noreply@forem.com
    # during the infrastructure setup and deploy.
    # For a Forem Cloud Account that has Custom SMTP settings we want to use the Settings::SMTP.reply_to_email_address
    # that the Forem will provide.
    # For a selfhosted Forem we want to use the Settings::SMTP.reply_to_email_address, which will already have a
    # default value of ApplicationConfig["DEFAULT_EMAIL"] set during their infrastructure setup even of they haven't
    # provided the minimum settings as yet.
    Settings::SMTP.provided_minimum_settings? ? Settings::SMTP.reply_to_email_address : email
  end

  def self.from_email_address
    # same comment applies from self.reply_to_email_address
    Settings::SMTP.provided_minimum_settings? ? Settings::SMTP.from_email_address : email
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
    Settings::SMTP.provided_minimum_settings? || ENV["SENDGRID_API_KEY"].present?
  end

  def self.sendgrid_enabled?
    ENV["SENDGRID_API_KEY"].present?
  end

  def self.only_sendgrid_enabled?
    ForemInstance.sendgrid_enabled? && !Settings::SMTP.provided_minimum_settings?
  end

  def self.invitation_only?
    Settings::Authentication.invite_only_mode?
  end

  def self.private?
    !Settings::UserExperience.public?
  end

  def self.needs_owner_secret?
    ENV["FOREM_OWNER_SECRET"].present? && Settings::General.waiting_on_first_user
  end
end
