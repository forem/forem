module DataUpdateScripts
  class SetContactEmailAddress
    def run
      return if SiteConfig.email_addresses[:contact].present?

      SiteConfig.email_addresses[:contact] = ApplicationConfig["DEFAULT_EMAIL"]
    end
  end
end
