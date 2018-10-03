StreamRails.enabled = false

p "1/8 Creating Organizations"

3.times do
  Organization.create!(
    name: Faker::SiliconValley.company,
    summary: Faker::Company.bs,
    remote_profile_image_url: logo = Faker::Company.logo,
    nav_image: logo,
    url: Faker::Internet.url,
    slug: "org#{rand(10000)}",
    github_username: "org#{rand(10000)}",
    twitter_username: "org#{rand(10000)}",
    bg_color_hex: Faker::Color.hex_color,
    text_color_hex: Faker::Color.hex_color,
  )
end

##############################################################################

p "2/8 Creating Users"

roles = %i(level_1_member level_2_member level_3_member level_4_member
           workshop_pass)
User.clear_index!
10.times do |i|
  user = User.create!(
    name: name = Faker::Name.unique.name,
    summary: Faker::Lorem.paragraph_by_chars(199, false),
    remote_profile_image_url: Faker::Avatar.image(nil, "300x300", "png", "set2", "bg2"),
    website_url: Faker::Internet.url,
    twitter_username: Faker::Internet.username(name),
    email_comment_notifications: false,
    email_follower_notifications: false,
    email: Faker::Internet.email(name, "+"),
    confirmed_at: Time.now,
    password: "password",
  )

  user.add_role(roles[rand(0..5)]) # includes chance of having no role

  Identity.create!(
    provider: "twitter",
    uid: i.to_s,
    token: i.to_s,
    secret: i.to_s,
    user: user,
    auth_data_dump: { "extra" => { "raw_info" => { "lang" => "en" } } },
  )
end

##############################################################################

p "3/8 Creating Tags"

tags = %w(beginners career computerscience git go
          java javascript linux productivity python security webdev)

tags.each do |tag_name|
  Tag.create!(
    name: tag_name,
    bg_color_hex: Faker::Color.hex_color,
    text_color_hex: Faker::Color.hex_color,
    supported: true,
  )
end

##############################################################################

p "4/8 Creating Articles"

Article.clear_index!
25.times do |i|
  tags = []
  tags << "discuss" if (i % 3).zero?
  tags.concat Tag.order("RANDOM()").select("name").first(3).map(&:name)

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
    user_id: User.order("RANDOM()").first.id,
  )
end

##############################################################################

p "5/8 Creating Comments"

Comment.clear_index!
30.times do
  attributes = {
    body_markdown: Faker::Hipster.paragraph(1),
    user_id: User.order("RANDOM()").first.id,
    commentable_id: Article.order("RANDOM()").first.id,
    commentable_type: "Article",
  }
  Comment.create!(attributes)
end

##############################################################################

p "6/8 Creating Podcasts"

image_file = File.join(
  Rails.root, "spec", "support", "fixtures", "images", "image1.jpeg"
)

podcast_objects = [
  {
    title: "CodingBlocks",
    description: "",
    feed_url: "http://feeds.podtrac.com/c8yBGHRafqhz",
    slug: "codingblocks",
    twitter_username: "CodingBlocks",
    website_url: "http://codingblocks.net",
    main_color_hex: "111111",
    overcast_url: "https://overcast.fm/itunes769189585/coding-blocks-software-and-web-programming-security-best-practices-microsoft-net", # rubocop:disable Metrics/LineLength
    android_url: "http://subscribeonandroid.com/feeds.podtrac.com/c8yBGHRafqhz",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
  },
  {
    title: "Talk Python",
    description: "",
    feed_url: "https://talkpython.fm/episodes/rss",
    slug: "talkpython",
    twitter_username: "TalkPython",
    website_url: "https://talkpython.fm",
    main_color_hex: "181a1c",
    overcast_url: "https://overcast.fm/itunes979020229/talk-python-to-me-python-conversations-for-passionate-developers", # rubocop:disable Metrics/LineLength
    android_url: "https://subscribeonandroid.com/talkpython.fm/episodes/rss",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
  },
  {
    title: "Developer on Fire",
    description: "",
    feed_url: "http://developeronfire.com/rss.xml",
    itunes_url: "https://itunes.apple.com/us/podcast/developer-on-fire/id1006105326", # rubocop:disable Metrics/LineLength
    slug: "developeronfire",
    twitter_username: "raelyard",
    website_url: "http://developeronfire.com",
    main_color_hex: "",
    overcast_url: "https://overcast.fm/itunes1006105326/developer-on-fire",
    android_url: "http://subscribeonandroid.com/developeronfire.com/rss.xml",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
  },
  {
    title: "Building Programmers",
    description: "",
    feed_url: "https://building.fireside.fm/rss",
    itunes_url: "https://itunes.apple.com/us/podcast/building-programmers/id1149043456", # rubocop:disable Metrics/LineLength
    slug: "buildingprogrammers",
    twitter_username: "run_kmc",
    website_url: "https://building.fireside.fm",
    main_color_hex: "140837",
    overcast_url: "https://overcast.fm/itunes1149043456/building-programmers",
    android_url: "https://subscribeonandroid.com/building.fireside.fm/rss",
    image: Rack::Test::UploadedFile.new(image_file, "image/jpeg"),
  },
]

podcast_objects.each do |attributes|
  Podcast.create!(attributes)
end

##############################################################################

p "7/8 Creating Broadcasts"

Broadcast.create!(
  title: "Welcome Notification",
  processed_html: "Welcome to dev.to! Start by introducing yourself in <a href='/welcome' data-no-instant>the welcome thread</a>.", # rubocop:disable Metrics/LineLength
  type_of: "Onboarding",
  sent: true,
)

##############################################################################

p "8/8 Creating chat_channel"

ChatChannel.clear_index!
ChatChannel.without_auto_index do
  ["Workshop", "Meta", "General"].each do |chan|
    ChatChannel.create!(
      channel_name: chan,
      channel_type: "open",
      slug: chan,
    )
  end
end
ChatChannel.reindex!

##############################################################################

puts <<-ASCII



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
