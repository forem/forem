module Settings
  class SMTP < RailsSettings::Base
    self.table_name = :settings_smtp

    OPTIONS = %i[address port authentication user_name password domain].freeze

    # The configuration is cached, change this if you want to force update
    # the cache, or call Settings::Smtp.clear_cache
    cache_prefix { "v1" }

    field :address, type: :string, default: ApplicationConfig["SMTP_ADDRESS"]
    field :authentication, type: :string, default: ApplicationConfig["SMTP_AUTHENTICATION"],
                           validates: { inclusion: %w[plain login cram_md5] }
    field :domain, type: :string, default: ApplicationConfig["SMTP_DOMAIN"]
    field :password, type: :string, default: ApplicationConfig["SMTP_PASSWORD"]
    field :port, type: :integer, default: ApplicationConfig["SMTP_PORT"]
    field :user_name, type: :string, default: ApplicationConfig["SMTP_USER_NAME"]
  end
end
