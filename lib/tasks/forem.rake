namespace :forem do
  desc "Performs basic setup for new Forem instances"
  task setup: :environment do
    puts "\n== Setting up profile fields =="
    ProfileFields::AddBaseFields.call
  end

  task health_check_token: :environment do
    puts Settings::General.health_check_token
  end
end
