FactoryBot.define do
  factory :custom_profile_field do
    profile
    sequence(:label) { |n| "Email #{n}" }
    description { "some description" }
  end
end
