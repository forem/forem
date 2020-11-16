module DataUpdateScripts
  class CreateProfileFields
    def run
      # NOTE: the CSV importer uses find_or_create_by for both fields and
      # groups, so this operation is idempotent.
      csv = Rails.root.join("lib/data/dev_profile_fields.csv")
      ProfileFields::ImportFromCsv.call(csv)
    end
  end
end
