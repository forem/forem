module DataUpdateScripts
  class RemoveSettingsDataUpdateScripts
    # This contains settings migration scripts and now obsolete scripts
    SCRIPTS_TO_REMOVE = %w[
      20210316091354_move_authentication_settings
      20210405034117_move_campaign_settings
      20210414060839_move_rate_limit_settings
      20210419063311_move_community_settings
      20210426023014_move_user_experience_settings

      20201228194641_append_collective_noun_to_community_name
      20201229230456_remove_collective_noun_from_site_config
    ].freeze

    def run
      DataUpdateScript.delete_by(file_name: SCRIPTS_TO_REMOVE)
    end
  end
end
