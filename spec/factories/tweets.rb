FactoryBot.define do
  factory :tweet do
    twitter_id_code { rand(10_000) }
    full_fetched_object_serialized { Faker::Book.title }
  end
end
