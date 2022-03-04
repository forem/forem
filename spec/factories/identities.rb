FactoryBot.define do
  sequence(:uid, 100_000) { |n| n }

  factory :identity do
    uid { generate(:uid) }
    provider { "github" }
    token { rand(100_000) }
    secret { rand(100_000) }
    auth_data_dump { OmniAuth.config.mock_auth.fetch(provider.to_sym) }
  end
end
