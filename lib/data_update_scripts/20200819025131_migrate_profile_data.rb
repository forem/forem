module DataUpdateScripts
  class MigrateProfileData
    def run
      User.find_each do |user|
        # NOTE: no production users have profiles yet, but we want this script
        # to be idempotent.
        next if user.profile.present?

        Profile.create(user: user, data: Profiles::ExtractData.call(user))
      end
    end
  end
end
