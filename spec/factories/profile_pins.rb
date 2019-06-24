FactoryBot.define do
  factory :profile_pin do
    pinnable_type { "Article" }
    profile_type  { "User" }
  end
end
