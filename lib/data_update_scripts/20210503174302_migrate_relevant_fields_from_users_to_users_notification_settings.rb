module DataUpdateScripts
  class MigrateRelevantFieldsFromUsersToUsersNotificationSettings
    def run
      User.ids.each do |id|
        MigrateUserNotificationSettingsWorker.perform_async id
      end
    end
  end
end
