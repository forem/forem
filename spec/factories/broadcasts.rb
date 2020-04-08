FactoryBot.define do
  factory :broadcast do
    active { true }

    factory :set_up_profile_broadcast do
      title          { "Welcome Notification: set_up_profile" }
      type_of        { "Welcome" }
      processed_html { "Welcome to DEV! 👋 I'm <a href='https://dev.to/sloan'>Sloan</a>, the community mascot and I'm here to help get you started. Let's begin by <a href='https://dev.to/settings'>setting up your profile</a>!" }
    end

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

    factory :customize_ux_broadcast do
      title          { "Welcome Notification: customize_experience" }
      type_of        { "Welcome" }
      processed_html { "Sloan here! 👋 Did you know that that you can customize your DEV experience? Try changing <a href='settings/ux'>your font and theme</a> and find the best style for you!" }
    end

    factory :customize_feed_broadcast do
      title          { "Welcome Notification: customize_feed" }
      type_of        { "Welcome" }
      processed_html { "Hi, it's me again! 👋 Now that you're a part of the DEV community, let's focus on personalizing your content. You can start by <a href='/tags'>following some tags</a> to help customize your feed! 🎉" }
    end

    factory :start_discussion_broadcast do
      title          { "Welcome Notification: start_discussion" }
      type_of        { "Welcome" }
      processed_html { "Sloan here! 👋 I noticed that you haven't <a href='https://dev.to/t/discuss'>started a discussion</a> yet. Starting a discussion is easy to do; just click on 'Write a Post' in the sidebar of the tag page to get started!" }
    end

    factory :ask_question_broadcast do
      title          { "Welcome Notification: ask_question" }
      type_of        { "Welcome" }
      processed_html { "Sloan here! 👋 I noticed that you haven't <a href='https://dev.to/t/explainlikeimfive'>asked a question</a> yet. Asking a question is easy to do; just click on 'Write a Post' in the sidebar of the tag page to get started!" }
    end

    factory :discuss_and_ask_broadcast do
      title          { "Welcome Notification: discuss_and_ask" }
      type_of        { "Welcome" }
      processed_html { "Sloan here! 👋 I noticed that you haven't <a href='https://dev.to/t/explainlikeimfive'>asked a question</a> or <a href='https://dev.to/t/discuss'>started a discussion</a> yet. It's easy to do both of these; just click on 'Write a Post' in the sidebar of the tag page to get started!" }
    end
  end
end
