namespace :profile_onboarding_fields do
  desc "Setup Onboarding with previously shown fields"
  task update: :environment do
    ProfileField.where(attribute_name: "summary").update(label: "Bio", show_in_onboarding: true)
    ProfileField.where(attribute_name: "location").update(label: "Where are you located?", show_in_onboarding: true)
    ProfileField.where(attribute_name: "employment_title").update(label: "What is your title?",
                                                                  show_in_onboarding: true)
    ProfileField.where(attribute_name: "employer_name").update(label: "Where do you work?", show_in_onboarding: true)
  end
end
