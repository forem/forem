FactoryBot.define do
  factory :broadcast do
    active { false }

    factory :welcome_broadcast do
      title { "Welcome Notification: welcome_thread" }
      type_of { "Welcome" }
      processed_html { "Sloan here again! 👋 DEV is a friendly community. Why not introduce yourself by leaving a comment in <a href='/welcome'>the welcome thread</a>!" }
    end

    # TODO: [@thepracticaldev/delightful] Remove onboarding factory once welcome notifications are live.
    factory :onboarding_broadcast do
      title { "Welcome Notification" }
      type_of { "Onboarding" }
      processed_html { "Welcome! Introduce yourself in our <a href='/welcome'>welcome thread!</a>" }
    end
  end

  trait :active do
    active { true }
  end
end
