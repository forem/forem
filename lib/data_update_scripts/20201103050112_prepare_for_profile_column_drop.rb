module DataUpdateScripts
  class PrepareForProfileColumnDrop
    HONEYCOMB_PREFIX = "data_update_20201103050112".freeze

    def run
      # Make sure all current DEV profile fields exist. The import task is
      # idempotent so we don't need further checkes here.
      dev_fields_csv = Rails.root.join("lib/data/dev_profile_fields.csv")
      ProfileFields::ImportFromCsv.call(dev_fields_csv)

      # Make sure all current profile data is migrated before we remove the
      # column from User. Also ensure we don't lose any data for custom fields,
      # even if these got temporarily disabled by a feature flag.
      User.includes(:profile).order(:id).find_each do |user|
        profile = user.profile
        user_data = Profiles::ExtractData.call(user)
        profile.update(data: profile.data.merge(user_data).compact)
      rescue StandardError => e
        Honeycomb.add_field("#{HONEYCOMB_PREFIX}.class", e.class)
        Honeycomb.add_field("#{HONEYCOMB_PREFIX}.message", e.message)
        Honeycomb.add_field("#{HONEYCOMB_PREFIX}.user_id", e.user_id)
        next
      ensure
        Rails.cache.write(HONEYCOMB_PREFIX, user.id, expires_in: 48.hours)
      end
    end
  end
end
