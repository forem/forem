module DataUpdateScripts
  class MigrateDataToWorkField
    QUERY = "data->>'employment_title' <> '' AND data->'work' IS NULL".freeze

    def run
      Profile.where(QUERY).ids.each do |profile_id|
        MigrateDataToWorkFieldWorker.perform_async(profile_id)
      end
    end
  end
end
