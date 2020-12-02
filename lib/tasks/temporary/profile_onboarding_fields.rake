namespace :profile_onboarding_fields do
  desc "Setup Onboarding with previously shown fields"
  task update: :environment do
    ProfileField.where(attribute_name: "summary").update("show_in_onboarding": true)
    ProfileField.where(attribute_name: "location").update("show_in_onboarding": true)
    ProfileField.where(attribute_name: "employment_title").update("show_in_onboarding": true)
    ProfileField.where(attribute_name: "employer_name").update("show_in_onboarding": true)
  end
end
