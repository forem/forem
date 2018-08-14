FactoryBot.define do
  factory :broadcast do
    sent false
  end

  trait :onboarding do
    title "Welcome Notification"
    type_of "Onboarding"
    processed_html "Welcome! Introduce yourself in our <a href='/welcome'>welcome thread!</a>"
  end

  trait :sent do
    sent true
  end
end
