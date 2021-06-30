module DataUpdateScripts
  class MigrateDataToWorkField
    QUERY = "data->>'employment_title' IS NOT NULL AND data->>'employment_title' <> ''".freeze

    def run
      Profile.where(QUERY).find_each do |profile|
        next if profile.work.present?

        work_info = profile.employment_title
        work_info << " at #{profile.employer_name}" if profile.employer_name.present?
        profile.update(work: work_info)
      end
    end
  end
end
