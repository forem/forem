FactoryBot.define do
  factory :device do
    association :user, strategy: :create
    token { "12345" }
    platform { Device::IOS }
    app_bundle { Faker::Internet.domain_name(subdomain: true) }
  end
end
