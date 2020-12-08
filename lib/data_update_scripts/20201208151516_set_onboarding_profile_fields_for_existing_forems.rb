module DataUpdateScripts
  class SetOnboardingProfileFieldsForExistingForems
    def run
      return unless User.count.positive?

      ProfileField.where(attribute_name: "summary").update(label: "Bio", show_in_onboarding: true)
      ProfileField.where(attribute_name: "location").update(label: "Location", show_in_onboarding: true)
      ProfileField.where(attribute_name: "employment_title").update(label: "Employer title",
                                                                    show_in_onboarding: true)
      ProfileField.where(attribute_name: "employer_name").update(label: "Employer name", show_in_onboarding: true)
    end
  end
end
