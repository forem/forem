namespace :temporary do
  desc "Create profile fields based on DEV profile" 
  task create_profile_fields: :environment do
    csv = Rails.root.join("lib/data/dev_profile_fields.csv")
    ProfileFields::ImportFromCsv.call(csv)
  end
end
