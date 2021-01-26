module DataUpdateScripts
  class SetContactEmailAddress
    def run
      # This script does not work as expected.
      # It does not create and update the contact email.
      # 20201218080343_update_default_email_addresses is a replacement.
      # return if SiteConfig.email_addresses[:contact].present?

      # SiteConfig.email_addresses[:contact] = ApplicationConfig["DEFAULT_EMAIL"]
    end
  end
end
