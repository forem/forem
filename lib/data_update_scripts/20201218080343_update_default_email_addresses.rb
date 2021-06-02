module DataUpdateScripts
  class UpdateDefaultEmailAddresses
    def run
      return if Settings::General.email_addresses[:contact].present?

      # In order to trigger the attribute setter on the Settings::General hash object,
      # it seems like we need to set all the values in the hash and not only the one we are changing.
      Settings::General.email_addresses = {
        default: Settings::General.email_addresses[:default],
        business: Settings::General.email_addresses[:business],
        privacy: Settings::General.email_addresses[:privacy],
        members: Settings::General.email_addresses[:members],
        contact: ApplicationConfig["DEFAULT_EMAIL"]
      }
    end
  end
end
