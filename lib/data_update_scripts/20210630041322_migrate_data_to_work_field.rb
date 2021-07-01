module DataUpdateScripts
  class MigrateDataToWorkField
    QUERY = "data->>'employment_title' <> '' AND data->>'work' IS NULL".freeze

    def run
      Profile.where(QUERY).select(:id).find_each do |profile|
        MigrateDataToWorkFieldWorker.perform_async(profile.id)
      end
    end
  end
end
