FactoryBot.define do
  factory :consumer_app do
    auth_key { Faker::Alphanumeric.alpha(number: 10) }
    active { true }
    platform { Device::IOS }
    app_bundle { Faker::Internet.domain_name(subdomain: true) }
  end
end
