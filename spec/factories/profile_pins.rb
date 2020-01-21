FactoryBot.define do
  factory :profile_pin do
    association :profile, factory: :user
    after(:build) do |profile_pin|
      profile_pin.pinnable ||= create(:article, user_id: profile_pin.profile_id)
    end
  end
end
