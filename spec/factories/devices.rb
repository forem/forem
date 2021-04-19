FactoryBot.define do
  factory :device do
    association :user, strategy: :create
    association :consumer_app, strategy: :create
    sequence(:token) { |n| "unique_token_#{n}" }
    platform { Device::IOS }
  end
end
