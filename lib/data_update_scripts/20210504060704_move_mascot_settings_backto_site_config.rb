module DataUpdateScripts
  class MoveMascotSettingsBacktoSiteConfig
    def run
      return unless Database.table_available?("settings_mascots")

      # Remove obsolete data update script
      DataUpdateScript.delete_by(file_name: "20210420050256_move_mascot_settings")

      # Migrate back explicitly set values
      mascot_image_url = Settings::Mascot.image_url
      SiteConfig.mascot_image_url = mascot_image_url if mascot_image_url

      mascot_user_id = Settings::Mascot.mascot_user_id
      SiteConfig.mascot_user_id = mascot_user_id if mascot_user_id
    end
  end
end
