FactoryBot.define do
  factory :profile_field do
    sequence(:label) { |n| "Email #{n}" }
    input_type { :text_field }
    placeholder_text { "john.doe@example.com" }
    active { true }
  end
end
