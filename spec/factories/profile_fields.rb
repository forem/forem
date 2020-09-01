FactoryBot.define do
  factory :profile_field do
    profile_field_group
    sequence(:label) { |n| "Email #{n}" }
    input_type { :text_field }
    description { "some description" }
    placeholder_text { "john.doe@example.com" }

    trait :onboarding do
      show_in_onboarding { true }
    end
  end
end
