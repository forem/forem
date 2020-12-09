module DataUpdateScripts
  class MigrateProfileData
    def run
      User.find_each do |user|
        # NOTE: This script is a no-op now, as we have removed the needed service
        # object.
        # next if user.profile.present?

        # Profile.create(user: user, data: Profiles::ExtractData.call(user))
      end
    end
  end
end
