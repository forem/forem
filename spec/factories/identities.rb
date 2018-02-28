FactoryBot.define do
  factory :identity do
    provider { "github" }
    uid { rand(100000) }
    token { rand(100000) }
    secret { rand(100000) }
  end
end
