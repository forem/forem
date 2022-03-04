module DataUpdateScripts
  class MarkMascotSettingDusAsObsolete
    def run
      DataUpdateScript.delete_by(file_name: "20210504060704_move_mascot_settings_backto_site_config")
    end
  end
end
