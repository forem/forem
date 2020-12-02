namespace :profile_onboarding_fields do
  desc "Setup Onboarding with previously shown fields"
  task update: :environment do
    ProfileField.where(attribute_name: "summary").update("show_in_onboarding": true)
    ProfileField.where(attribute_name: "location").update("show_in_onboarding": true)
    ProfileField.where(attribute_name: "employment_title").update("show_in_onboarding": true)
    ProfileField.where(attribute_name: "employer_name").update("show_in_onboarding": true)

    # update the summary to be a text area instead of a text field
    ProfileField.where(attribute_name: "summary").update("input_type": 1)
  end
end
