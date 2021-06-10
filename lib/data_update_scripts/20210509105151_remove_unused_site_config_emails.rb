module DataUpdateScripts
  class RemoveUnusedSiteConfigEmails
    def run
      Settings::General.email_addresses = {
        default: ApplicationConfig["DEFAULT_EMAIL"]
      }
    end
  end
end
