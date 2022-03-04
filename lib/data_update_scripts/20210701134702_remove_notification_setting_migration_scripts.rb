module DataUpdateScripts
  class RemoveNotificationSettingMigrationScripts
    SCRIPTS_TO_REMOVE = %w[
      20210423155327_migrate_relevant_fields_from_users_to_users_settings
      20210503174302_migrate_relevant_fields_from_users_to_users_notification_settings
    ].freeze

    def run
      DataUpdateScript.delete_by(file_name: SCRIPTS_TO_REMOVE)
    end
  end
end
