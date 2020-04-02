# we use this to be able to increase the size of the seeded DB at will
# eg.: `SEEDS_MULTIPLIER=2 rails db:seed` would double the amount of data
SEEDS_MULTIPLIER = [1, ENV["SEEDS_MULTIPLIER"].to_i].max
counter = 0
Rails.logger.info "Seeding with multiplication factor: #{SEEDS_MULTIPLIER}"

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Organizations"

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

##############################################################################

num_users = 10 * SEEDS_MULTIPLIER

counter += 1
Rails.logger.info "#{counter}. Creating #{num_users} Users"

User.clear_index!

roles = %i[trusted chatroom_beta_tester workshop_pass]

num_users.times do |i|
  name = Faker::Name.unique.name

  user = User.create!(
    name: name,
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    twitter_username: Faker::Internet.username(specifier: name),
    email_comment_notifications: false,
    email_follower_notifications: false,
    email: Faker::Internet.email(name: name, separators: "+", domain: Faker::Internet.domain_word.first(20)), # Emails limited to 50 characters
    confirmed_at: Time.current,
    password: "password",
  )

  if i.zero?
    user.add_role(:trusted) # guarantee at least one moderator
  else
    user.add_role(roles[rand(0..roles.length)]) # includes chance of having no role
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

users_in_random_order = User.order(Arel.sql("RANDOM()"))

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Tags"

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

##############################################################################

num_articles = 25 * SEEDS_MULTIPLIER

counter += 1
Rails.logger.info "#{counter}. Creating #{num_articles} Articles"

Article.clear_index!

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

##############################################################################

num_comments = 30 * SEEDS_MULTIPLIER

counter += 1
Rails.logger.info "#{counter}. Creating #{num_comments} Comments"

num_comments.times do
  attributes = {
    body_markdown: Faker::Hipster.paragraph(sentence_count: 1),
    user_id: User.order(Arel.sql("RANDOM()")).first.id,
    commentable_id: Article.order(Arel.sql("RANDOM()")).first.id,
    commentable_type: "Article"
  }

  Comment.create!(attributes)
end

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Podcasts"

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
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
    published: true
  },
  {
    title: "CodingBlocks",
    description: "",
    feed_url: "http://feeds.podtrac.com/c8yBGHRafqhz",
    slug: "codingblocks",
    twitter_username: "CodingBlocks",
    website_url: "http://codingblocks.net",
    main_color_hex: "111111",
    overcast_url: "https://overcast.fm/itunes769189585/coding-blocks",
    android_url: "http://subscribeonandroid.com/feeds.podtrac.com/c8yBGHRafqhz",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
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
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
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
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
    published: true
  },
]

podcast_objects.each do |attributes|
  podcast = Podcast.create!(attributes)
  Podcasts::GetEpisodesWorker.perform_async(podcast_id: podcast.id)
end

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Broadcasts and Welcome Thread"

# TODO: [@thepracticaldev/delightful] Remove this once we have launched welcome notifications.
Broadcast.create!(
  title: "Welcome Notification",
  processed_html: "Welcome to dev.to! Start by introducing yourself in <a href='/welcome' data-no-instant>the welcome thread</a>.",
  type_of: "Onboarding",
  active: true,
)

broadcast_messages = {
  set_up_profile: "Welcome to DEV! 👋 I'm Sloan, the community mascot and I'm here to help get you started. Let's begin by <a href='/settings'>setting up your profile</a>!",
  welcome_thread: "Sloan here again! 👋 DEV is a friendly community. Why not introduce yourself by leaving a comment in <a href='/welcome'>the welcome thread</a>!",
  twitter_connect: "You're on a roll! 🎉 Let's connect your <a href='/settings'> Twitter account</a> to complete your identity so that we don't think you're a robot. 🤖",
  github_connect: "You're on a roll! 🎉 Let's connect your <a href='/settings'> GitHub account</a> to complete your identity so that we don't think you're a robot. 🤖",
  customize_feed: "Hi, it's me again! 👋 Now that you're a part of the DEV community, let's focus on personalizing your content. You can start by <a href='/tags'>following some tags</a> to help customize your feed! 🎉",
  customize_experience: "Sloan here! 👋 Did you know that that you can customize your DEV experience? Try changing <a href='settings/ux'>your font and theme</a> and find the best style for you!",
  start_discussion: "Sloan here! 👋 I noticed that you haven't <a href='https://dev.to/t/discuss'>started a discussion</a> yet. Starting a discussion is easy to do; just click on 'Write a Post' in the sidebar of the tag page to get started!",
  ask_question: "Sloan here! 👋 I noticed that you haven't <a href='https://dev.to/t/explainlikeimfive'>asked a question</a> yet. Asking a question is easy to do; just click on 'Write a Post' in the sidebar of the tag page to get started!",
  discuss_and_ask: "Sloan here! 👋 I noticed that you haven't <a href='https://dev.to/t/explainlikeimfive'>asked a question</a> or <a href='https://dev.to/t/discuss'>started a discussion</a> yet. It's easy to do both of these; just click on 'Write a Post' in the sidebar of the tag page to get started!"
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

  Hey there! Welcome to #{ApplicationConfig['COMMUNITY_NAME']}!

  Leave a comment below to introduce yourself to the community!✌️
HEREDOC

Article.create!(
  body_markdown: welcome_thread_content,
  user: User.dev_account,
)

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Chat Channels and Messages"

%w[Workshop Meta General].each do |chan|
  ChatChannel.create!(
    channel_name: chan,
    channel_type: "open",
    slug: chan,
  )
end

direct_channel = ChatChannel.create_with_users(users: User.last(2), channel_type: "direct")
Message.create!(
  chat_channel: direct_channel,
  user: User.last,
  message_markdown: "This is **awesome**",
)

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating HTML Variants"

HtmlVariant.create!(
  name: rand(100).to_s,
  group: "badge_landing_page",
  html: rand(1000).to_s,
  success_rate: 0,
  published: true,
  approved: true,
  user_id: User.first.id,
)

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Badges"

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


##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating FeedbackMessages"

mod = User.first

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
  Reaction.create!(
    category: "vomit",
    reactable_id: Article.order(Arel.sql("RANDOM()")).first.id,
    reactable_type: "Article",
    user_id: mod.id,
  )
end

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Classified Listings"

users_in_random_order.each { |user| Credit.add_to(user, rand(100)) }
users = users_in_random_order.to_a

listings_categories = ClassifiedListing.categories_available.keys
listings_categories.each_with_index do |category, index|
  # rotate users if they are less than the categories
  user = users.at((index + 1) % users.length)
  2.times do
    ClassifiedListing.create!(
      user: user,
      title: Faker::Lorem.sentence,
      body_markdown: Faker::Markdown.random,
      location: Faker::Address.city,
      organization_id: user.organizations.first&.id,
      category: category,
      contact_via_connect: true,
      published: true,
      bumped_at: Time.current,
      tag_list: Tag.order(Arel.sql("RANDOM()")).first(2).pluck(:name),
    )
  end
end

##############################################################################

counter += 1
Rails.logger.info "#{counter}. Creating Pages"

5.times do
  Page.create!(
    title: Faker::Hacker.say_something_smart,
    body_markdown: Faker::Markdown.random,
    slug: Faker::Internet.slug,
    description: Faker::Books::Dune.quote,
    template: %w[contained full_within_layout].sample,
  )
end

##############################################################################

puts <<-ASCII # rubocop:disable Rails/Output



  ```````````````````````````````````````````````````````````````````````````
  ```````````````````````````````````````````````````````````````````````````
  ```````````````````````````````````````````````````````````````````````````
  ```````````````````````````````````````````````````````````````````````````
  ```````````````````````````````````````````````````````````````````````````
  ``````````````-oooooooo/-``````.+ooooooooo:``+ooo+````````oooo/````````````
  ``````````````+MMMMMMMMMMm+```-NMMMMMMMMMMs``+MMMM:``````/MMMM/````````````
  ``````````````+MMMNyyydMMMMy``/MMMMyyyyyyy/```mMMMd``````mMMMd`````````````
  ``````````````+MMMm````:MMMM.`/MMMN```````````/MMMM/````/MMMM:`````````````
  ``````````````+MMMm````.MMMM-`/MMMN````````````dMMMm````mMMMh``````````````
  ``````````````+MMMm````.MMMM-`/MMMMyyyy+```````:MMMM/``+MMMM-``````````````
  ``````````````+MMMm````.MMMM-`/MMMMMMMMy````````hMMMm``NMMMy```````````````
  ``````````````+MMMm````.MMMM-`/MMMMoooo:````````-MMMM+oMMMM-```````````````
  ``````````````+MMMm````.MMMM-`/MMMN``````````````yMMMmNMMMy````````````````
  ``````````````+MMMm````+MMMM.`/MMMN``````````````.MMMMMMMM.````````````````
  ``````````````+MMMMdddNMMMMo``/MMMMddddddd+```````sMMMMMMs`````````````````
  ``````````````+MMMMMMMMMNh:```.mMMMMMMMMMMs````````yMMMMs``````````````````
  ``````````````.///////:-````````-/////////-`````````.::.```````````````````
  ```````````````````````````````````````````````````````````````````````````
  ```````````````````````````````````````````````````````````````````````````
  ```````````````````````````````````````````````````````````````````````````
  ```````````````````````````````````````````````````````````````````````````

  All done!
ASCII
