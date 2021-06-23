module DataUpdateScripts
  class UpdateDefaultEmailAddresses
    def run
      return if SiteConfig.email_addresses[:contact].present?

      # In order to trigger the attribute setter on the SiteConfig hash object,
      # it seems like we need to set all the values in the hash and not only the one we are changing.
      SiteConfig.email_addresses = {
        default: SiteConfig.email_addresses[:default],
        business: SiteConfig.email_addresses[:business],
        privacy: SiteConfig.email_addresses[:privacy],
        members: SiteConfig.email_addresses[:members],
        contact: ApplicationConfig["DEFAULT_EMAIL"]
      }
    end
  end
end
