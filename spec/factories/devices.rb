FactoryBot.define do
  factory :device do
    association :user, strategy: :create
    sequence(:token) { |n| "unique_token_#{n}" }
    platform { Device::IOS }
    app_bundle { Faker::Internet.domain_name(subdomain: true) }
  end
end
