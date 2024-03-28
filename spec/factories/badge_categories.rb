FactoryBot.define do
  factory :badge_category do
    name { Faker::Lorem.characters(number: 15) }
    description { Faker::Lorem.sentence }
  end
end
