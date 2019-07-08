FactoryBot.define do
  sequence(:uid, 100_000) { |n| n }

  factory :identity do
    uid { generate(:uid) }
    provider { "github" }
    token { rand(100_000) }
    secret { rand(100_000) }
    auth_data_dump do
      {
        "info" => {
          "nickname" => "something"
        }
      }
    end
  end
end
