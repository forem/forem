FactoryBot.define do
  factory :profile_pin do
    association :profile, factory: :user
    after(:build) do |profile_pin|
      next if profile_pin.profile_type == "Organization"

      profile_pin.pinnable ||= create(:article, user: profile_pin.profile)
    end

    trait :for_organization do
      association :profile, factory: :organization
      after(:build) do |profile_pin|
        profile_pin.pinnable ||= create(:article, organization: profile_pin.profile)
      end
    end
  end
end
