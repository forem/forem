FactoryBot.define do
  factory :navigation_link do
    name { "#{Faker::Book.title} #{rand(1000)}" }
    url  { "#{Faker::Internet.url}/#{rand(1000)}" }
    icon { "<svg xmlns='http://www.w3.org/2000/svg'/></svg>" }
  end
end
