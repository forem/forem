FactoryBot.define do
  factory :user_visit_context do
    geolocation { "MyString" }
    user_agent { "MyString" }
    accept_language { "MyString" }
    visit_count { 1 }
    last_visit_at { "2021-10-05 00:03:52" }
    user { nil }
  end
end
