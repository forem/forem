module DataUpdateScripts
  class PrepareForProfileColumnDrop
    def run
      # Make sure all current DEV profile fields exist. The import task is
      # idempotent so we don't need further checkes here.
      dev_fields_csv = Rails.root.join("lib/data/dev_profile_fields.csv")
      ProfileFields::ImportFromCsv.call(dev_fields_csv)

      # Make sure all current profile data is migrated before we remove the
      # column from User. Also ensure we don't lose any data for custom fields,
      # even if these got temporarily disabled by a feature flag.
      User.includes(:profile).find_each do |user|
        profile = user.profile
        user_data = Profiles::ExtractData.call(user)
        profile.update(data: profile.data.merge(user_data.compact))
      end
    end
  end
end
