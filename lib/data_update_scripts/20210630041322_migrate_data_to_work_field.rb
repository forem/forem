module DataUpdateScripts
  class MigrateDataToWorkField
    # NOTE: data->>'employment_title' <> '' takes care of both null and empty strings.
    # This works for two reasons:
    # 1. We use the JSONB ->> operator, which coerces the result to text. This also
    # turns JSONB `null` into "Postgres" `null`.
    # See: https://www.postgresql.org/docs/13/functions-json.html
    # 2. `null` is neither equal to nor unequal to any string. For this reason
    # `stringexpression <> ''` can be used to filter both `null`s and empty strings.
    # See: https://stackoverflow.com/questions/23766084/best-way-to-check-for-empty-or-null-value
    QUERY = "data->>'employment_title' <> '' AND data->>'work' IS NULL".freeze

    def run
      Profile.where(QUERY).select(:id).find_each do |profile|
        MigrateDataToWorkFieldWorker.perform_async(profile.id)
      end
    end
  end
end
