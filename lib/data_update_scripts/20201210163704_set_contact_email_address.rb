module DataUpdateScripts
  class SetContactEmailAddress
    def run
      return if SiteConfig.email_addresses[:contact].present?

      # This update does not create and update the contact email,
      # wrote 20201218080343_update_default_email_addresses as a replacement.
      SiteConfig.email_addresses[:contact] = ApplicationConfig["DEFAULT_EMAIL"]
    end
  end
end
