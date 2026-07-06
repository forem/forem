FactoryBot.define do
  factory :event_signup do
    association :user
    association :event
  end
end
