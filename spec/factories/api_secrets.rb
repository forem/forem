FactoryBot.define do
  factory :api_secret do
    user
    description { Faker::Lorem.sentence.truncate(ApiSecret::DESCRIPTION_MAX_LENGTH) }
    secret      { SecureRandom.base58(24) }
  end
end
