FactoryBot.define do
  factory :profile_field_group do
    sequence(:name) { |n| "Test Group #{n}" }
    description { "Group for testing profile fields" }
  end
end
