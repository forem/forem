FactoryBot.define do
  factory :device do
    association :user, strategy: :create
    association :app_integration, strategy: :create
    sequence(:token) { |n| "unique_token_#{n}" }
    platform { Device::IOS }
  end
end
