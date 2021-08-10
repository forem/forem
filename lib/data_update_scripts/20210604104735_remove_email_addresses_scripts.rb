module DataUpdateScripts
  class RemoveEmailAddressesScripts
    def run
      DataUpdateScript.delete_by(file_name: "20210509105151_remove_unused_site_config_emails")
      Settings::General.delete_by(var: :email_addresses)
    end
  end
end
