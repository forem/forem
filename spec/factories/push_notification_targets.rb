FactoryBot.define do
  factory :push_notification_target do
    auth_key { Faker::Alphanumeric.alpha(number: 10) }
    enabled { true }
    platform { Device::IOS }
    app_bundle { Faker::Internet.domain_name(subdomain: true) }
  end
end
