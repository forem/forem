FactoryBot.define do
  factory :badge do
    title { Faker::Overwatch.quote }
    description { Faker::Lorem.sentence }
  end
end
