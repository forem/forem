FactoryBot.define do
  factory :profile_field do
    sequence(:label) { |n| "Email #{n}" }
    input_type { :text_field }
    description { "some description" }
    placeholder_text { "john.doe@example.com" }
    active { true }
    group { "Basic" }
  end
end
