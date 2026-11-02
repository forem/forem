FactoryBot.define do
  factory :organization_email_domain do
    organization
    requested_by factory: :user
    domain { "foobar.com" }

    trait :available do
      status { "approved" }
      enabled { true }
    end
  end
end
