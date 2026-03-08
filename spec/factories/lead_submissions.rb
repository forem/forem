FactoryBot.define do
  factory :lead_submission do
    organization_lead_form
    user
    name { "Test User" }
    email { "test@example.com" }
  end
end
