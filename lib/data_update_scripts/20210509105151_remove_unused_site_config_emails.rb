module DataUpdateScripts
  class RemoveUnusedSiteConfigEmails
    def run
      SiteConfig.email_addresses = {
        default: ApplicationConfig["DEFAULT_EMAIL"]
      }
    end
  end
end
