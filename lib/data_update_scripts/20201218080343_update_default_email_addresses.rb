module DataUpdateScripts
  class UpdateDefaultEmailAddresses
    def run
      return if Settings::General.email_addresses[:default].present?

      Settings::General.email_addresses = {
        default: ApplicationConfig["DEFAULT_EMAIL"]
      }
    end
  end
end
