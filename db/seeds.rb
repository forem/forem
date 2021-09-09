# rubocop:disable Rails/Output

return if Rails.env.production?

# NOTE: when adding new data, please use the Seeder class to ensure the seed tasks
# stays idempotent.
require Rails.root.join("app/lib/seeder")

# we use this to be able to increase the size of the seeded DB at will
# eg.: `SEEDS_MULTIPLIER=2 rails db:seed` would double the amount of data
seeder = Seeder.new
SEEDS_MULTIPLIER = [1, ENV["SEEDS_MULTIPLIER"].to_i].max
puts "Seeding with multiplication factor: #{SEEDS_MULTIPLIER}\n\n"

##############################################################################
# Default development settings are different from production scenario

Settings::UserExperience.public = true
Settings::General.waiting_on_first_user = false
Settings::Authentication.providers = Authentication::Providers.available

##############################################################################

# Disable Redis cache while seeding
Rails.cache = ActiveSupport::Cache.lookup_store(:null_store)

# Put forem into "starter mode"

if ENV["MODE"] == "STARTER"
  Settings::UserExperience.public = false
  Settings::General.waiting_on_first_user = true
  puts "Seeding forem in starter mode to replicate new creator experience"
  exit # We don't need any models if we're launching things from startup.
end

seeder.create_if_none(Organization) do
  3.times do
    Organization.create!(
      name: Faker::TvShows::SiliconValley.company,
      summary: Faker::Company.bs,
      remote_profile_image_url: logo = Faker::Company.logo,
      nav_image: logo,
      url: Faker::Internet.url,
      slug: "org#{rand(10_000)}",
      github_username: "org#{rand(10_000)}",
      twitter_username: "org#{rand(10_000)}",
      bg_color_hex: Faker::Color.hex_color,
      text_color_hex: Faker::Color.hex_color,
    )
  end
end

##############################################################################

num_users = 10 * SEEDS_MULTIPLIER

users_in_random_order = seeder.create_if_none(User, num_users) do
  roles = %i[trusted chatroom_beta_tester workshop_pass]

  num_users.times do |i|
    name = Faker::Name.unique.name

    user = User.create!(
      name: name,
      profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
      twitter_username: Faker::Internet.username(specifier: name),
      # Emails limited to 50 characters
      email: Faker::Internet.email(name: name, separators: "+", domain: Faker::Internet.domain_word.first(20)),
      confirmed_at: Time.current,
      registered_at: Time.current,
      registered: true,
      password: "password",
      password_confirmation: "password",
    )

    user.profile.update(
      summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
      website_url: Faker::Internet.url,
    )

    if i.zero?
      user.add_role(:trusted) # guarantee at least one moderator
    elsif i == num_users - 1
      next # guarantee at least one user with no role
    else
      role_index = rand(0..roles.length)
      user.add_role(roles[role_index]) if role_index != roles.length # increases chance of more no-role users
    end

    Identity.create!(
      provider: "twitter",
      uid: i.to_s,
      token: i.to_s,
      secret: i.to_s,
      user: user,
      auth_data_dump: {
        "extra" => {
          "raw_info" => { "lang" => "en" }
        },
        "info" => { "nickname" => user.username }
      },
    )
  end

  Organization.find_each do |organization|
    admins = []
    admin_id = User.where.not(id: admins).order(Arel.sql("RANDOM()")).first.id

    OrganizationMembership.create!(
      user_id: admin_id,
      organization_id: organization.id,
      type_of_user: "admin",
    )

    admins << admin_id

    2.times do
      OrganizationMembership.create!(
        user_id: User.where.not(id: OrganizationMembership.pluck(:user_id)).order(Arel.sql("RANDOM()")).first.id,
        organization_id: organization.id,
        type_of_user: "member",
      )
    end
  end

  User.order(Arel.sql("RANDOM()"))
end

seeder.create_if_doesnt_exist(User, "email", "admin@forem.local") do
  user = User.create!(
    name: "Admin McAdmin",
    email: "admin@forem.local",
    username: "Admin_McAdmin",
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
  )

  user.profile.update(
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    website_url: Faker::Internet.url,
  )

  user.add_role(:super_admin)
  user.add_role(:tech_admin)
end

Users::CreateMascotAccount.call unless Settings::General.mascot_user_id

##############################################################################

seeder.create_if_none(Tag) do
  tags = %w[beginners career computerscience git go
            java javascript linux productivity python security webdev]

  tags.each do |tag_name|
    Tag.create!(
      name: tag_name,
      bg_color_hex: Faker::Color.hex_color,
      text_color_hex: Faker::Color.hex_color,
      supported: true,
    )
  end
end

##############################################################################

num_articles = 25 * SEEDS_MULTIPLIER

seeder.create_if_none(Article, num_articles) do
  num_articles.times do |i|
    tags = []
    tags << "discuss" if (i % 3).zero?
    tags.concat Tag.order(Arel.sql("RANDOM()")).limit(3).pluck(:name)

    markdown = <<~MARKDOWN
      ---
      title:  #{Faker::Book.title} #{Faker::Lorem.sentence(word_count: 2).chomp('.')}
      published: true
      cover_image: #{Faker::Company.logo}
      tags: #{tags.join(', ')}
      ---

      #{Faker::Hipster.paragraph(sentence_count: 2)}
      #{Faker::Markdown.random}
      #{Faker::Hipster.paragraph(sentence_count: 2)}
    MARKDOWN

    Article.create!(
      body_markdown: markdown,
      featured: true,
      show_comments: true,
      user_id: User.order(Arel.sql("RANDOM()")).first.id,
    )
  end
end

##############################################################################

num_comments = 30 * SEEDS_MULTIPLIER

seeder.create_if_none(Comment, num_comments) do
  num_comments.times do
    attributes = {
      body_markdown: Faker::Hipster.paragraph(sentence_count: 1),
      user_id: User.order(Arel.sql("RANDOM()")).first.id,
      commentable_id: Article.order(Arel.sql("RANDOM()")).first.id,
      commentable_type: "Article"
    }

    Comment.create!(attributes)
  end
end

##############################################################################

seeder.create_if_none(Podcast) do
  image_file = Rails.root.join("spec/support/fixtures/images/image1.jpeg")

  podcast_objects = [
    {
      title: "CodeNewbie",
      description: "",
      feed_url: "http://feeds.codenewbie.org/cnpodcast.xml",
      itunes_url: "https://itunes.apple.com/us/podcast/codenewbie/id919219256",
      slug: "codenewbie",
      twitter_username: "CodeNewbies",
      website_url: "https://www.codenewbie.org/podcast",
      main_color_hex: "2faa4a",
      overcast_url: "https://overcast.fm/itunes919219256/codenewbie",
      android_url: "https://subscribeonandroid.com/feeds.podtrac.com/q8s8ba9YtM6r",
      image: Pathname.new(image_file).open,
      published: true
    },
    {
      title: "CodingBlocks",
      description: "",
      feed_url: "https://www.codingblocks.net/podcast-feed.xml",
      slug: "codingblocks",
      twitter_username: "CodingBlocks",
      website_url: "http://codingblocks.net",
      main_color_hex: "111111",
      overcast_url: "https://overcast.fm/itunes769189585/coding-blocks",
      android_url: "http://subscribeonandroid.com/feeds.podtrac.com/c8yBGHRafqhz",
      image: Pathname.new(image_file).open,
      published: true
    },
    {
      title: "Talk Python",
      description: "",
      feed_url: "https://talkpython.fm/episodes/rss",
      slug: "talkpython",
      twitter_username: "TalkPython",
      website_url: "https://talkpython.fm",
      main_color_hex: "181a1c",
      overcast_url: "https://overcast.fm/itunes979020229/talk-python-to-me",
      android_url: "https://subscribeonandroid.com/talkpython.fm/episodes/rss",
      image: Pathname.new(image_file).open,
      published: true
    },
    {
      title: "Developer on Fire",
      description: "",
      feed_url: "http://developeronfire.com/rss.xml",
      itunes_url: "https://itunes.apple.com/us/podcast/developer-on-fire/id1006105326",
      slug: "developeronfire",
      twitter_username: "raelyard",
      website_url: "http://developeronfire.com",
      main_color_hex: "343d46",
      overcast_url: "https://overcast.fm/itunes1006105326/developer-on-fire",
      android_url: "http://subscribeonandroid.com/developeronfire.com/rss.xml",
      image: Pathname.new(image_file).open,
      published: true
    },
  ]

  podcast_objects.each do |attributes|
    podcast = Podcast.create!(attributes)
    Podcasts::GetEpisodesWorker.perform_async(podcast_id: podcast.id)
  end
end
##############################################################################

seeder.create_if_none(Broadcast) do
  broadcast_messages = {
    set_up_profile: "Welcome to DEV! 👋 I'm Sloan, the community mascot and I'm here to help get you started. " \
                    "Let's begin by <a href='/settings'>setting up your profile</a>!",
    welcome_thread: "Sloan here again! 👋 DEV is a friendly community. " \
                    "Why not introduce yourself by leaving a comment in <a href='/welcome'>the welcome thread</a>!",
    twitter_connect: "You're on a roll! 🎉 Do you have a Twitter account? " \
                     "Consider <a href='/settings'>connecting it</a> so we can @mention you if we share your post " \
                     "via our Twitter account <a href='https://twitter.com/thePracticalDev'>@thePracticalDev</a>.",
    facebook_connect: "You're on a roll! 🎉  Do you have a Facebook account? " \
                      "Consider <a href='/settings'>connecting it</a>.",
    github_connect: "You're on a roll! 🎉  Do you have a GitHub account? " \
                    "Consider <a href='/settings'>connecting it</a> so you can pin any of your repos to your profile.",
    customize_feed:
      "Hi, it's me again! 👋 Now that you're a part of the DEV community, let's focus on personalizing " \
      "your content. You can start by <a href='/tags'>following some tags</a> to help customize your feed! 🎉",
    customize_experience:
      "Sloan here! 👋 Did you know that that you can customize your DEV experience? " \
      "Try changing <a href='settings/customization'>your font and theme</a> and find the best style for you!",
    start_discussion:
      "Sloan here! 👋 I noticed that you haven't " \
      "<a href='https://dev.to/t/discuss'>started a discussion</a> yet. Starting a discussion is easy to do; " \
      "just click on 'Create Post' in the sidebar of the tag page to get started!",
    ask_question:
      "Sloan here! 👋 I noticed that you haven't " \
      "<a href='https://dev.to/t/explainlikeimfive'>asked a question</a> yet. Asking a question is easy to do; " \
      "just click on 'Create Post' in the sidebar of the tag page to get started!",
    discuss_and_ask:
      "Sloan here! 👋 I noticed that you haven't " \
      "<a href='https://dev.to/t/explainlikeimfive'>asked a question</a> or " \
      "<a href='https://dev.to/t/discuss'>started a discussion</a> yet. It's easy to do both of these; " \
      "just click on 'Create Post' in the sidebar of the tag page to get started!",
    download_app: "Sloan here, with one last tip! 👋 Have you downloaded the DEV mobile app yet? " \
                  "Consider <a href='https://dev.to/downloads'>downloading</a> it so you can access all " \
                  "of your favorite DEV content on the go!"
  }

  broadcast_messages.each do |type, message|
    Broadcast.create!(
      title: "Welcome Notification: #{type}",
      processed_html: message,
      type_of: "Welcome",
      active: true,
    )
  end

  welcome_thread_content = <<~HEREDOC
    ---
    title: Welcome Thread - v0
    published: true
    description: Introduce yourself to the community!
    tags: welcome
    ---

    Hey there! Welcome to #{Settings::Community.community_name}!

    Leave a comment below to introduce yourself to the community!✌️
  HEREDOC

  Article.create!(
    body_markdown: welcome_thread_content,
    user: User.staff_account || User.first,
  )
end

##############################################################################

seeder.create_if_none(ChatChannel) do
  %w[Workshop Meta General].each do |chan|
    ChatChannel.create!(
      channel_name: chan,
      channel_type: "open",
      slug: chan,
    )
  end

  # This channel is hard-coded in a few places
  ChatChannel.create!(
    channel_name: "Tag Moderators",
    channel_type: "open",
    slug: "tag-moderators",
  )

  direct_channel = ChatChannels::CreateWithUsers.call(users: User.last(2), channel_type: "direct")
  Message.create!(
    chat_channel: direct_channel,
    user: User.last,
    message_markdown: "This is **awesome**",
  )
end

##############################################################################

seeder.create_if_none(HtmlVariant) do
  HtmlVariant.create!(
    name: rand(100).to_s,
    group: "badge_landing_page",
    html: rand(1000).to_s,
    success_rate: 0,
    published: true,
    approved: true,
    user_id: User.first.id,
  )
end

##############################################################################

seeder.create_if_none(Badge) do
  5.times do
    Badge.create!(
      title: "#{Faker::Lorem.word} #{rand(100)}",
      description: Faker::Lorem.sentence,
      badge_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    )
  end

  users_in_random_order.limit(10).each do |user|
    user.badge_achievements.create!(
      badge: Badge.order(Arel.sql("RANDOM()")).limit(1).take,
      rewarding_context_message_markdown: Faker::Markdown.random,
    )
  end
end

##############################################################################

seeder.create_if_none(FeedbackMessage) do
  mod = User.with_role(:trusted).take

  FeedbackMessage.create!(
    reporter: User.last,
    feedback_type: "spam",
    message: Faker::Lorem.sentence,
    category: "spam",
    status: "Open",
  )

  FeedbackMessage.create!(
    reporter: mod,
    feedback_type: "abuse-reports",
    message: Faker::Lorem.sentence,
    reported_url: "example.com",
    category: "harassment",
    status: "Open",
  )

  Reaction.create!(
    category: "vomit",
    reactable_id: User.last.id,
    reactable_type: "User",
    user_id: mod.id,
  )

  3.times do
    article_id = Article
      .left_joins(:reactions)
      .where.not(articles: { id: Reaction.article_vomits.pluck(:reactable_id) })
      .order(Arel.sql("RANDOM()"))
      .first
      .id

    Reaction.create!(
      category: "vomit",
      reactable_id: article_id,
      reactable_type: "Article",
      user_id: mod.id,
    )
  end
end

##############################################################################

seeder.create_if_none(ListingCategory) do
  categories = [
    {
      slug: "cfp",
      cost: 1,
      name: "Conference CFP",
      rules: "Currently open for proposals, with link to form."
    },
    {
      slug: "education",
      cost: 1,
      name: "Education/Courses",
      rules: "Educational material and/or schools/bootcamps."
    },
    {
      slug: "jobs",
      cost: 25,
      name: "Job Listings",
      rules: "Companies offering employment right now."
    },
    {
      slug: "forsale",
      cost: 1,
      name: "Stuff for Sale",
      rules: "Personally owned physical items for sale."
    },
    {
      slug: "events",
      cost: 1,
      name: "Upcoming Events",
      rules: "In-person or online events with date included."
    },
    {
      slug: "misc",
      cost: 1,
      name: "Miscellaneous",
      rules: "Must not fit in any other category."
    },
  ].freeze

  categories.each { |attributes| ListingCategory.create(attributes) }
end

##############################################################################

seeder.create_if_none(Listing) do
  users_in_random_order = User.order(Arel.sql("RANDOM()"))
  users_in_random_order.each { |user| Credit.add_to(user, rand(100)) }
  users = users_in_random_order.to_a

  listings_categories = ListingCategory.ids
  listings_categories.each.with_index(1) do |category_id, index|
    # rotate users if they are less than the categories
    user = users.at(index % users.length)
    2.times do
      Listing.create!(
        user: user,
        title: Faker::Lorem.sentence,
        body_markdown: Faker::Markdown.random.lines.take(10).join,
        location: Faker::Address.city,
        organization_id: user.organizations.first&.id,
        listing_category_id: category_id,
        contact_via_connect: true,
        published: true,
        originally_published_at: Time.current,
        bumped_at: Time.current,
        tag_list: Tag.order(Arel.sql("RANDOM()")).first(2).pluck(:name),
      )
    end
  end
end

##############################################################################

seeder.create_if_none(Page) do
  5.times do
    Page.create!(
      title: Faker::Hacker.say_something_smart,
      body_markdown: Faker::Markdown.random,
      slug: Faker::Internet.slug,
      description: Faker::Books::Dune.quote,
      template: %w[contained full_within_layout].sample,
    )
  end
end

##############################################################################

seeder.create_if_none(Sponsorship) do
  organizations = Organization.take(3)
  organizations.each do |organization|
    Sponsorship.create!(
      organization: organization,
      user: User.order(Arel.sql("RANDOM()")).first,
      level: "silver",
      blurb_html: Faker::Hacker.say_something_smart,
    )
  end
end

##############################################################################

seeder.create_if_none(NavigationLink) do
  Rake::Task["navigation_links:update"].invoke
end

##############################################################################

puts <<-ASCII

  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  ::::'########::'#######::'########::'########:'##::::'##::::
  :::: ##.....::'##.... ##: ##.... ##: ##.....:: ###::'###::::
  :::: ##::::::: ##:::: ##: ##:::: ##: ##::::::: ####'####::::
  :::: ######::: ##:::: ##: ########:: ######::: ## ### ##::::
  :::: ##...:::: ##:::: ##: ##.. ##::: ##...:::: ##. #: ##::::
  :::: ##::::::: ##:::: ##: ##::. ##:: ##::::::: ##:.:: ##::::
  :::: ##:::::::. #######:: ##:::. ##: ########: ##:::: ##::::
  ::::..:::::::::.......:::..:::::..::........::..:::::..:::::
  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

  All done!
ASCII

# rubocop:enable Rails/Output
