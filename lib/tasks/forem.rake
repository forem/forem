namespace :forem do
  desc "Performs basic setup for new Forem instances"
  task setup: :environment do
    puts "\n== Setting up profile fields =="
    ProfileField.destroy_all
    ProfileFields::AddBaseFields.call
  end
end
