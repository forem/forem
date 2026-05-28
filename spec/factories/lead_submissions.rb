FactoryBot.define do
  factory :lead_submission do
    organization_lead_form
    user
    name { "Test User" }
    email { "test@example.com" }

    trait :anonymous do
      user { nil }
      name { "Anonymous User" }
      email { "anon@example.com" }
    end
  end
end
