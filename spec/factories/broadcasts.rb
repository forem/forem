FactoryBot.define do
  factory :broadcast do
    active { true }
    active_status_updated_at { 2.days.ago }

    factory :set_up_profile_broadcast do
      title          { "Welcome Notification: set_up_profile" }
      type_of        { "Welcome" }
      processed_html do
        "Welcome to DEV! 👋 I'm <a href='https://dev.to/sloan'>Sloan</a>, " \
        "the community mascot and I'm here to help get you started. " \
        "Let's begin by <a href='https://dev.to/settings'>setting up your profile</a>!"
      end
    end

    factory :welcome_broadcast do
      title          { "Welcome Notification: welcome_thread" }
      type_of        { "Welcome" }
      processed_html do
        "Sloan here again! 👋 DEV is a friendly community. " \
        "Why not introduce yourself by leaving a comment in <a href='/welcome'>the welcome thread</a>!"
      end
    end

    factory :apple_connect_broadcast do
      title          { "Welcome Notification: apple_connect" }
      type_of        { "Welcome" }
      processed_html do
        "You're on a roll! 🎉  Do you have an Apple account? Consider <a href='/settings'>connecting it</a>."
      end
    end

    factory :github_connect_broadcast do
      title          { "Welcome Notification: github_connect" }
      type_of        { "Welcome" }
      processed_html do
        "You're on a roll! 🎉  Do you have a GitHub account? Consider " \
        "<a href='/settings'>connecting it</a> so you can pin any of your repos to your profile."
      end
    end

    factory :facebook_connect_broadcast do
      title          { "Welcome Notification: facebook_connect" }
      type_of        { "Welcome" }
      processed_html do
        "You're on a roll! 🎉  Do you have a Facebook account? Consider " \
        "<a href='/settings'>connecting it</a>."
      end
    end

    factory :twitter_connect_broadcast do
      title          { "Welcome Notification: twitter_connect" }
      type_of        { "Welcome" }
      processed_html do
        "You're on a roll! 🎉 Do you have a Twitter account? Consider " \
        "<a href='/settings'>connecting it</a> so we can @mention you if we share " \
        "your post via our Twitter account <a href='https://twitter.com/thePracticalDev'>@thePracticalDev</a>."
      end
    end

    factory :customize_ux_broadcast do
      title          { "Welcome Notification: customize_experience" }
      type_of        { "Welcome" }
      processed_html do
        "Sloan here! 👋 Did you know that that you can customize your DEV experience? " \
        "Try changing <a href='settings/customization'>your font and theme</a> and find the best style for you!"
      end
    end

    factory :customize_feed_broadcast do
      title          { "Welcome Notification: customize_feed" }
      type_of        { "Welcome" }
      processed_html do
        "Hi, it's me again! 👋 Now that you're a part of the DEV community, " \
        "let's focus on personalizing your content. You can start by " \
        "<a href='/tags'>following some tags</a> to help customize your feed! 🎉"
      end
    end

    factory :start_discussion_broadcast do
      title          { "Welcome Notification: start_discussion" }
      type_of        { "Welcome" }
      processed_html do
        "Sloan here! 👋 I noticed that you haven't " \
        "<a href='https://dev.to/t/discuss'>started a discussion</a> yet. " \
        "Starting a discussion is easy to do; just click on 'Create Post' " \
        "in the sidebar of the tag page to get started!"
      end
    end

    factory :ask_question_broadcast do
      title          { "Welcome Notification: ask_question" }
      type_of        { "Welcome" }
      processed_html do
        "Sloan here! 👋 I noticed that you haven't " \
        "<a href='https://dev.to/t/explainlikeimfive'>asked a question</a> yet. " \
        "Asking a question is easy to do; just click on 'Create Post' in the sidebar of the tag page to get started!"
      end
    end

    factory :discuss_and_ask_broadcast do
      title          { "Welcome Notification: discuss_and_ask" }
      type_of        { "Welcome" }
      processed_html do
        "Sloan here! 👋 I noticed that you haven't " \
        "<a href='https://dev.to/t/explainlikeimfive'>asked a question</a> or " \
        "<a href='https://dev.to/t/discuss'>started a discussion</a> yet. " \
        "It's easy to do both of these; just click on 'Create Post' in the sidebar of the tag page to get started!"
      end
    end

    factory :download_app_broadcast do
      title          { "Welcome Notification: download_app" }
      type_of        { "Welcome" }
      processed_html do
        "Sloan here, with one last tip! 👋 Have you downloaded the DEV mobile " \
        "app yet? Consider <a href='https://dev.to/downloads'>downloading</a> it " \
        "so you can access all of your favorite DEV content on the go!"
      end
    end

    factory :announcement_broadcast do
      title          { "A Very Important Announcement" }
      type_of        { "Announcement" }
      processed_html { "<p>Hello, World!</p>" }
    end

    trait :with_tracking do
      processed_html do
        "Sloan here again! 👋 DEV is a friendly community. Why not introduce " \
        "yourself by leaving a comment in <a href='/welcome' onclick='trackNotification(event)'>the welcome thread</a>!"
      end
    end
  end
end
