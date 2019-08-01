Rails.logger.info "1. Creating Organizations"

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

Rails.logger.info "2. Creating Users"

roles = %i[trusted chatroom_beta_tester workshop_pass]
User.clear_index!
10.times do |i|
  user = User.create!(
    name: name = Faker::Name.unique.name,
    summary: Faker::Lorem.paragraph_by_chars(199, false),
    profile_image: File.open(Rails.root.join("app", "assets", "images", "#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    twitter_username: Faker::Internet.username(name),
    email_comment_notifications: false,
    email_follower_notifications: false,
    email: Faker::Internet.email(name, "+"),
    confirmed_at: Time.current,
    password: "password",
  )

  user.add_role(roles[rand(0..3)]) # includes chance of having no role

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

##############################################################################

Rails.logger.info "3. Creating Tags"

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

Rails.logger.info "4. Creating Articles"

Article.clear_index!
25.times do |i|
  tags = []
  tags << "discuss" if (i % 3).zero?
  tags.concat Tag.order(Arel.sql("RANDOM()")).select("name").first(3).map(&:name)

  markdown = <<~MARKDOWN
    ---
    title:  #{Faker::Book.unique.title}
    published: true
    cover_image: #{Faker::Company.logo}
    tags: #{tags.join(', ')}
    ---

    #{Faker::Hipster.paragraph(2)}
    #{Faker::Markdown.random}
    #{Faker::Hipster.paragraph(2)}
  MARKDOWN

  Article.create!(
    body_markdown: markdown,
    featured: true,
    show_comments: true,
    user_id: User.order(Arel.sql("RANDOM()")).first.id,
  )
end

##############################################################################

Rails.logger.info "5. Creating Comments"

Comment.clear_index!
30.times do
  attributes = {
    body_markdown: Faker::Hipster.paragraph(1),
    user_id: User.order(Arel.sql("RANDOM()")).first.id,
    commentable_id: Article.order(Arel.sql("RANDOM()")).first.id,
    commentable_type: "Article"
  }
  Comment.create!(attributes)
end

##############################################################################

Rails.logger.info "6. Creating Podcasts"

image_file = Rails.root.join("spec", "support", "fixtures", "images", "image1.jpeg")

podcast_objects = [
  {
    title: "CodingBlocks",
    description: "",
    feed_url: "http://feeds.podtrac.com/c8yBGHRafqhz",
    slug: "codingblocks",
    twitter_username: "CodingBlocks",
    website_url: "http://codingblocks.net",
    main_color_hex: "111111",
    overcast_url: "https://overcast.fm/itunes769189585/coding-blocks-software-and-web-programming-security-best-practices-microsoft-net",
    android_url: "http://subscribeonandroid.com/feeds.podtrac.com/c8yBGHRafqhz",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg")
  },
  {
    title: "Talk Python",
    description: "",
    feed_url: "https://talkpython.fm/episodes/rss",
    slug: "talkpython",
    twitter_username: "TalkPython",
    website_url: "https://talkpython.fm",
    main_color_hex: "181a1c",
    overcast_url: "https://overcast.fm/itunes979020229/talk-python-to-me-python-conversations-for-passionate-developers",
    android_url: "https://subscribeonandroid.com/talkpython.fm/episodes/rss",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg")
  },
  {
    title: "Developer on Fire",
    description: "",
    feed_url: "http://developeronfire.com/rss.xml",
    itunes_url: "https://itunes.apple.com/us/podcast/developer-on-fire/id1006105326",
    slug: "developeronfire",
    twitter_username: "raelyard",
    website_url: "http://developeronfire.com",
    main_color_hex: Faker::Color.hex_color,
    overcast_url: "https://overcast.fm/itunes1006105326/developer-on-fire",
    android_url: "http://subscribeonandroid.com/developeronfire.com/rss.xml",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg")
  },
  {
    title: "Building Programmers",
    description: "",
    feed_url: "https://building.fireside.fm/rss",
    itunes_url: "https://itunes.apple.com/us/podcast/building-programmers/id1149043456",
    slug: "buildingprogrammers",
    twitter_username: "run_kmc",
    website_url: "https://building.fireside.fm",
    main_color_hex: "140837",
    overcast_url: "https://overcast.fm/itunes1149043456/building-programmers",
    android_url: "https://subscribeonandroid.com/building.fireside.fm/rss",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg")
  },
]

podcast_objects.each do |attributes|
  Podcast.create!(attributes)
end

##############################################################################

Rails.logger.info "7. Creating Broadcasts"

Broadcast.create!(
  title: "Welcome Notification",
  processed_html: "Welcome to dev.to! Start by introducing yourself in <a href='/welcome' data-no-instant>the welcome thread</a>.",
  type_of: "Onboarding",
  sent: true,
)

##############################################################################

Rails.logger.info "8. Creating Chat Channels and Messages"

ChatChannel.clear_index!
ChatChannel.without_auto_index do
  %w[Workshop Meta General].each do |chan|
    ChatChannel.create!(
      channel_name: chan,
      channel_type: "open",
      slug: chan,
    )
  end

  direct_channel = ChatChannel.create_with_users(User.last(2), "direct")
  Message.create!(
    chat_channel: direct_channel,
    user: User.last,
    message_markdown: "This is **awesome**",
  )
end
ChatChannel.reindex!

Rails.logger.info "9. Creating HTML Variants"

HtmlVariant.create!(
  name: rand(100).to_s,
  group: "badge_landing_page",
  html: rand(1000).to_s,
  success_rate: 0,
  published: true,
  approved: true,
  user_id: User.first.id,
)

Rails.logger.info "10. Creating Badges"

Badge.create!(
  title: Faker::Lorem.word,
  description: Faker::Lorem.sentence,
  badge_image: File.open(Rails.root.join("app", "assets", "images", "#{rand(1..40)}.png")),
)

Rails.logger.info "11. Creating FeedbackMessages"

FeedbackMessage.create!(
  reporter: User.last,
  feedback_type: "spam",
  message: Faker::Lorem.sentence,
  category: "spam",
  status: "Open",
)

Rails.logger.info "12. Creating Classified listings"

users = User.order(Arel.sql("RANDOM()")).to_a
users.each { |user| Credit.add_to(user, rand(100)) }

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
      category: category,
      contact_via_connect: true,
      published: true,
      bumped_at: Time.current,
    )
  end
end
##############################################################################

Rails.logger.info <<-ASCII



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
