FactoryBot.define do
  factory :api_secret do
    user
    description { Faker::Lorem.sentence }
    secret      { SecureRandom.base58(24) }
  end
end
