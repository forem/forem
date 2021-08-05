FactoryBot.define do
  factory :profile_field do
    profile_field_group
    sequence(:label) { |n| "Email #{n}" }
    input_type { :text_field }
    description { "some description" }
    placeholder_text { "john.doe@example.com" }
    show_in_onboarding { false }
    display_area { :left_sidebar }

    trait :onboarding do
      show_in_onboarding { true }
    end

    trait :header do
      display_area { :header }
    end

    after :create do
      # this is accomplished by ProfileFields::Add normally, it was added here
      # in case the tests use the factory and not the service object
      Profile.refresh_attributes!
    end
  end
end
