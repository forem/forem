FactoryBot.define do
  sequence(:uid, 100000) { |n| n }

  factory :identity do
    uid { generate(:uid) }
    provider { "github" }
    token { rand(100000) }
    secret { rand(100000) }
  end
end
