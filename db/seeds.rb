# p "1/7 Creating orgs"
# 3.times do
#   attributes = { name: Faker::Book.title,
#                 summary: Faker::Hipster.paragraph(1),
#                 profile_image: File.open("#{Rails.root}/app/assets/images/android-icon-36x36.png"),
#                 nav_image: Faker::Avatar.image,
#                 url: Faker::Internet.url,
#                 slug: "org#{rand(10000)}",
#                 github_username: "org#{rand(10000)}",
#                 twitter_username: "org#{rand(10000)}",
#                 bg_color_hex: Faker::Color.hex_color,
#                 text_color_hex: Faker::Color.hex_color
#               }
#   Organization.create!(attributes)
# end

# # Create users

# p "2/7 Creating users"
# roles = %i(level_1_member level_2_member level_3_member level_4_member workshop_pass)
# 80.times do |i|
#   begin
#     identity_attributes = { provider: "twitter",
#                             uid: "#{i}",
#                             token: "#{i}",
#                             secret: "#{i}",}
#     identity = Identity.create(identity_attributes)
#     user_attributes = {
#                     name: Faker::Name.name,
#                     summary: Faker::Hipster.paragraph(1),
#                     profile_image: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'fixtures', 'images', 'image1.jpeg'), 'image/jpeg'),
#                     website_url: Faker::Internet.url,
#                     twitter_username: "twitter_#{i}",
#                     email_comment_notifications: false,
#                     email_follower_notifications: false,
#                     email: Faker::Internet.email,
#                     confirmed_at: Time.now,
#                     password: "password",
#                  }
#     user = User.create!(user_attributes)
#     user.add_role(roles[rand(0..4)])
#     identity.user = user
#     identity.save!
#   rescue
#     p "error creating user"
#   end
# end

# # Create their articles

# p "3/7 Creating Tags"
# Tag.create!(
#   name: "beginners",
#   bg_color_hex: "#ffa500",
#   text_color_hex: "#ffffff",
#   supported: true,
#   )
# Tag.create!(
#   name: "career",
#   bg_color_hex: "#2a2566",
#   text_color_hex: "#ffffff",
#   supported: true,
# )
# Tag.create!(
#   name: "computerscience",
#   bg_color_hex: "#dbd3fd",
#   text_color_hex: "#0c0040",
#   supported: true,
#   )
# Tag.create!(
#   name: "git",
#   bg_color_hex: "#F54D27",
#   text_color_hex: "#413932",
#   supported: true,
# )
# Tag.create!(
#   name: "go",
#   bg_color_hex: "#E0EBF5",
#   text_color_hex: "#03284a",
#   supported: true,
# )
# Tag.create!(
#   name: "java",
#   bg_color_hex: "#01476e",
#   text_color_hex: "#ff8f8f",
#   supported: true,
#   )
# Tag.create!(
#   name: "javascript",
#   bg_color_hex: "#f7df1e",
#   text_color_hex: "#000000",
#   supported: true,
# )
# Tag.create!(
#   name: "linux",
#   bg_color_hex: "#008ddd",
#   text_color_hex: "#ffffff",
#   supported: true,
# )
# Tag.create!(
#   name: "productivity",
#   bg_color_hex: "#88a2cc",
#   text_color_hex: "#262524",
#   supported: true,
# )
# Tag.create!(
#   name: "python",
#   bg_color_hex: "#1e38bb",
#   text_color_hex: "#FFDF5B",
#   supported: true,
# )
# Tag.create!(
#   name: "security",
#   bg_color_hex: "#000000",
#   text_color_hex: "#ffffff",
#   supported: true,
# )
# Tag.create!(
#   name: "webdev",
#   bg_color_hex: "#562765",
#   text_color_hex: "#ffffff",
#   supported: true,
# )

# p "4/7 Creating articles"
# 150.times do
#   # begin
#     four_tags_string = "discuss, meta, git, changelog"
#     valid_markdown = "---\ntitle:  #{Faker::Book.title} #{rand(5000)}\npublished: true\ncover_image: #{Faker::Avatar.image}\ntags: #{four_tags_string}\n---\n#{Faker::Hipster.paragraph(4)}"
#     attributes = {
#       body_markdown: valid_markdown,
#       featured: true,
#       show_comments: true,
#       user_id: User.order("RANDOM()").first.id,
#     }
#     Article.create!(attributes)
#   # rescue
#   #   p "error creating article"
#   # end
# end

# # Create comments

# p "5/7 Creating comments"
# 200.times do
#   attributes = {
#     body_markdown: Faker::Hipster.paragraph(1),
#     user_id: User.order("RANDOM()").first.id,
#     commentable_id: Article.order("RANDOM()").first.id,
#     commentable_type: "Article",
#   }
#   Comment.create!(attributes)
# end

# # Create podcasts

# p "6/7 Creating podcasts"
# podcast_objects = [
#   {"title"=>"CodingBlocks", "description"=>nil, "feed_url"=>"http://feeds.podtrac.com/c8yBGHRafqhz", "image"=> Faker::Avatar.image, "slug"=>"codingblocks", "twitter_username"=>"CodingBlocks", "website_url"=>"http://codingblocks.net", "main_color_hex"=>"111111", "overcast_url"=>"https://overcast.fm/itunes769189585/coding-blocks-software-and-web-programming-security-best-practices-microsoft-net", "android_url"=>"http://subscribeonandroid.com/feeds.podtrac.com/c8yBGHRafqhz", image: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'fixtures', 'images', 'image1.jpeg'), 'image/jpeg')},
#   {"title"=>"Talk Python", "description"=>nil, "feed_url"=>"https://talkpython.fm/episodes/rss", "image"=> Faker::Avatar.image, "slug"=>"talkpython", "twitter_username"=>"TalkPython", "website_url"=>"https://talkpython.fm", "main_color_hex"=>"181a1c", "overcast_url"=>"https://overcast.fm/itunes979020229/talk-python-to-me-python-conversations-for-passionate-developers", "android_url"=>"https://subscribeonandroid.com/talkpython.fm/episodes/rss", image: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'fixtures', 'images', 'image1.jpeg'), 'image/jpeg')},
#   {"title"=>"Developer on Fire", "description"=>"", "feed_url"=>"http://developeronfire.com/rss.xml", "itunes_url"=>"https://itunes.apple.com/us/podcast/developer-on-fire/id1006105326", "image"=> Faker::Avatar.image, "slug"=>"developeronfire", "twitter_username"=>"raelyard", "website_url"=>"http://developeronfire.com", "main_color_hex"=>"", "overcast_url"=>"https://overcast.fm/itunes1006105326/developer-on-fire", "android_url"=>"http://subscribeonandroid.com/developeronfire.com/rss.xml", image: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'fixtures', 'images', 'image1.jpeg'), 'image/jpeg')},
#   {"title"=>"Building Programmers", "description"=>"", "feed_url"=>"https://building.fireside.fm/rss", "itunes_url"=>"https://itunes.apple.com/us/podcast/building-programmers/id1149043456", "image"=> Faker::Avatar.image, "slug"=>"buildingprogrammers", "twitter_username"=>"run_kmc", "website_url"=>"https://building.fireside.fm", "main_color_hex"=>"140837", "overcast_url"=>"https://overcast.fm/itunes1149043456/building-programmers", "android_url"=>"https://subscribeonandroid.com/building.fireside.fm/rss", image: Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'fixtures', 'images', 'image1.jpeg'), 'image/jpeg')},
# ]

# podcast_objects.each do |attributes|
#   podcast = Podcast.create!(attributes)
#   PodcastFeed.new.get_episodes(podcast, 4)
# end

# p "7/7 Creating Broadcasts"
# Broadcast.create!(
#   title: "Welcome Notification",
#   processed_html: "Welcome to dev.to! Start by introducing yourself in <a href='/welcome' data-no-instant>the welcome thread</a>.",
#   type_of: "Onboarding",
#   sent: true,
# )
