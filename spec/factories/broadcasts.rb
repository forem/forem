FactoryBot.define do
  factory :broadcast do
    active { false }
  end

  trait :onboarding do
    title { "Onboarding Notification" }
    type_of { "Onboarding" }
    processed_html { "Welcome! Introduce yourself in our <a href='/welcome'>welcome thread!</a>" }
  end

  trait :active do
    active { true }
  end
end
