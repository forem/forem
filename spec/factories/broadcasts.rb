FactoryBot.define do
  factory :broadcast do
    active { true }

    factory :welcome_broadcast do
      title          { "Welcome Notification: welcome_thread" }
      type_of        { "Welcome" }
      processed_html { "Sloan here again! 👋 DEV is a friendly community. Why not introduce yourself by leaving a comment in <a href='/welcome'>the welcome thread</a>!" }
    end

    factory :twitter_connect_broadcast do
      title          { "Welcome Notification: twitter_connect" }
      type_of        { "Welcome" }
      processed_html { "You're on a roll! 🎉 Let's connect your <a href='/settings'> Twitter account</a> to complete your identity so that we don't think you're a robot. 🤖" }
    end

    factory :github_connect_broadcast do
      title          { "Welcome Notification: github_connect" }
      type_of        { "Welcome" }
      processed_html { "You're on a roll! 🎉 Let's connect your <a href='/settings'> GitHub account</a> to complete your identity so that we don't think you're a robot. 🤖" }
    end

    # TODO: [@thepracticaldev/delightful] Remove onboarding factory once welcome notifications are live.
    factory :onboarding_broadcast do
      title          { "Welcome Notification" }
      type_of        { "Onboarding" }
      processed_html { "Welcome! Introduce yourself in our <a href='/welcome'>welcome thread!</a>" }
    end
  end
end
