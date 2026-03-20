FactoryBot.define do
  factory :organization_lead_form do
    organization
    title { "Get our newsletter" }
    description { "Sign up to receive weekly updates." }
    button_text { "Sign Up" }
    active { true }
  end
end
