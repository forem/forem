FactoryBot.define do
  factory :navigation_link do
    name { "Test Link" }
    url  { "https://www.test.com" }
    icon { "<svg xmlns='http://www.w3.org/2000/svg'/></svg>" }
  end
end
