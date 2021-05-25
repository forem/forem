module DataUpdateScripts
  class MigrateRelevantFieldsFromUsersToUsersSettings
    def run
      User.ids.each do |id|
        MigrateUserSettingsWorker.perform_async id
      end
    end
  end
end
