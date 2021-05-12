module DataUpdateScripts
  class RemoveSettingsDataUpdateScripts
    def run
      DataUpdateScript.delete_by(file_name: "20210316091354_move_authentication_settings")
      DataUpdateScript.delete_by(file_name: "20210405034117_move_campaign_settings")
      DataUpdateScript.delete_by(file_name: "20210414060839_move_rate_limit_settings")
      DataUpdateScript.delete_by(file_name: "20210419063311_move_community_settings")
      DataUpdateScript.delete_by(file_name: "20210426023014_move_user_experience_settings")
    end
  end
end
