namespace :temporary do
  desc "Migrate existing profile data"
  task migrate_profiles: :environment do
    User.find_each do |user|
      Profile.create(user: user, data: Profiles::ExtractData.call(user))
    end
  end
end
