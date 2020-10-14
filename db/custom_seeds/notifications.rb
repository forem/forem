# Notification seed file, to mock notifications for a specific user (ideally yourself).
# To run the command, run:
# rails db:seed:notifications USERNAME='your_username'
# you can also add CLEAN_SETUP="y" if you want to start with fresh notifications.

require "#{Rails.root}/db/seeder"

NUM_TOTAL_STEPS = 11

user = User.find_by(username: ENV["USERNAME"])
if user.blank?
  puts "Your user not found. Please ensure the username is present or that the command was properly run: rails db:seed:notifications USERNAME='your_username'"
  raise StandardError
end

if ENV["CLEAN_SETUP"].present?
  puts "starting with none of your existing notifications, followers, articles, and comments..."
  user.notifications.delete_all
  Follow.where(followable: user).destroy_all
  Follow.where(follower: user).destroy_all
  user.articles.destroy_all
  user.comments.destroy_all
end

seeder = Seeder.new

puts "0/#{NUM_TOTAL_STEPS} checking requirements..."
users = User.where(id: 1..6).count == 6 ? User.where(id: 1..6) : []
((1..6).to_a - users.pluck(:id)).each do |id|
  user = User.create!(
    id: id,
    name: name,
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    twitter_username: Faker::Internet.username(specifier: name),
    email_comment_notifications: false,
    email_follower_notifications: false,
    # Emails limited to 50 characters
    email: Faker::Internet.email(name: name, separators: "+", domain: Faker::Internet.domain_word.first(20)),
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
  )
  users.push(user)
end

puts "1/#{NUM_TOTAL_STEPS} seeding broadcast notifications..."
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
    customize_feed: "Hi, it's me again! 👋 Now that you're a part of the DEV community, let's focus on personalizing " \
      "your content. You can start by <a href='/tags'>following some tags</a> to help customize your feed! 🎉",
    customize_experience: "Sloan here! 👋 Did you know that that you can customize your DEV experience? " \
      "Try changing <a href='settings/ux'>your font and theme</a> and find the best style for you!",
    start_discussion: "Sloan here! 👋 I noticed that you haven't " \
      "<a href='https://dev.to/t/discuss'>started a discussion</a> yet. Starting a discussion is easy to do; " \
      "just click on 'Write a Post' in the sidebar of the tag page to get started!",
    ask_question: "Sloan here! 👋 I noticed that you haven't " \
      "<a href='https://dev.to/t/explainlikeimfive'>asked a question</a> yet. Asking a question is easy to do; " \
      "just click on 'Write a Post' in the sidebar of the tag page to get started!",
    discuss_and_ask: "Sloan here! 👋 I noticed that you haven't " \
      "<a href='https://dev.to/t/explainlikeimfive'>asked a question</a> or " \
      "<a href='https://dev.to/t/discuss'>started a discussion</a> yet. It's easy to do both of these; " \
      "just click on 'Write a Post' in the sidebar of the tag page to get started!",
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

    Hey there! Welcome to #{SiteConfig.community_name}!

    Leave a comment below to introduce yourself to the community!✌️
  HEREDOC

  Article.create!(
    body_markdown: welcome_thread_content,
    user: User.dev_account || User.first,
  )
end

Broadcast.all.each do |broadcast|
  Notifications::WelcomeNotification::Send.call(user.id, broadcast)
end

puts "2/#{NUM_TOTAL_STEPS} seeding follower notifications..."
# three followers notification
users[0..2].each do |follower|
  follow = Follow.find_or_create_by!(followable: user, follower: follower)
  Notification.send_new_follower_notification_without_delay(follow)
end

# two followers notification
follow = users[3].follow(user)
users[4].follow(user)
Notification.create!(
  notifiable: follow,
  action: "Follow",
  user: user,
  json_data: {
    user: Notifications.user_data(users[3]),
    aggregated_siblings: [
      Notifications.user_data(users[3]),
      Notifications.user_data(users[4])
    ]
  }
)

# one follower notification
follow = users[-1].follow(user)
Notification.create!(
  notifiable: follow,
  action: "Follow",
  user: user,
  json_data: {
    user: Notifications.user_data(users[-1]),
    aggregated_siblings: [
      Notifications.user_data(users[-1])
    ]
  }
)

puts "3/#{NUM_TOTAL_STEPS} seeding badge achievement notification.."
# badge achievement notification
seeder.create_if_none(Badge) do
  Badge.create!(
    title: "#{Faker::Lorem.word} #{rand(100)}",
    description: Faker::Lorem.sentence,
    badge_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
  )
end

seeder.create_if_doesnt_exist(BadgeAchievement, "user_id", user.id) do
  BadgeAchievement.create(user_id: user.id, badge: Badge.last, rewarding_context_message_markdown: "reward message, written via markdown")
end
Notifications::NewBadgeAchievement::Send.call(BadgeAchievement.last)

puts "4/#{NUM_TOTAL_STEPS} seeding reaction on article notifications..."
# three reactions on article notification
markdown = <<~MARKDOWN
  ---
  title: 3+ Reactions Article Title ##{rand(100)}
  published: true
  cover_image: #{Faker::Company.logo}
  tags: beginners, career, computerscience
  ---
​
  #{Faker::Hipster.paragraph(sentence_count: 2)}
  #{Faker::Markdown.random}
  #{Faker::Hipster.paragraph(sentence_count: 2)}
MARKDOWN
your_article = Article.create!(
  body_markdown: markdown,
  featured: true,
  show_comments: true,
  user: user,
)

users[0..2].each do |reactor|
  rxn = Reaction.create!(reactable: your_article, user: reactor, category: "like")
  Notification.send_reaction_notification_without_delay(rxn, user)
end

# two reactions on article notification
markdown = <<~MARKDOWN
  ---
  title:  Two Reactions Article Title ##{rand(100)}
  published: true
  cover_image: #{Faker::Company.logo}
  tags: beginners, career, computerscience
  ---
​
  #{Faker::Hipster.paragraph(sentence_count: 2)}
  #{Faker::Markdown.random}
  #{Faker::Hipster.paragraph(sentence_count: 2)}
MARKDOWN
double_rxn_article = Article.create!(
    body_markdown: markdown,
  featured: true,
  show_comments: true,
  user: user,
)
double_rxns = users[3..4].map do |reactor|
  Reaction.create!(reactable: double_rxn_article, user: reactor, category: "like")
end
Notification.create!(
  user: user,
  action: "Reaction",
  notifiable: double_rxn_article,
  json_data: {
    user: Notifications.user_data(User.first),
    reaction: {
      category: double_rxns[0].category,
      reactable_type: double_rxns[0].reactable_type,
      reactable_id: double_rxns[0].reactable_id,
      reactable: {
        path: double_rxns[0].reactable.path,
        title: double_rxns[0].reactable.title,
        class: {
          name: "Article"
        },
      },
      aggregated_siblings: double_rxns.map do |reaction|
        { category: reaction.category, created_at: reaction.created_at, user: Notifications.user_data(reaction.user) }
      end
    }
  }
)

# single reaction on article notification
markdown = <<~MARKDOWN
  ---
  title:  Single Reaction Article Title ##{rand(100)}
  published: true
  cover_image: #{Faker::Company.logo}
  tags: beginners, career, computerscience
  ---
​
  #{Faker::Hipster.paragraph(sentence_count: 2)}
  #{Faker::Markdown.random}
  #{Faker::Hipster.paragraph(sentence_count: 2)}
MARKDOWN
single_rxn_article = Article.create!(
    body_markdown: markdown,
  featured: true,
  show_comments: true,
  user: user,
)
rxn = Reaction.create!(reactable: single_rxn_article, user: users[-1], category: "like")
Notification.create!(
  user: user,
  action: "Reaction",
  notifiable: single_rxn_article,
  json_data: {
    user: Notifications.user_data(users[-1]),
    reaction: {
      category: rxn.category,
      reactable_type: rxn.reactable_type,
      reactable_id: rxn.reactable_id,
      reactable: {
        path: rxn.reactable.path,
        title: rxn.reactable.title,
        class: {
          name: "Article"
        },
      },
      aggregated_siblings:  [
        { category: rxn.category, created_at: rxn.created_at, user: Notifications.user_data(rxn.user) }
      ]
    }
  }
)

puts "5/#{NUM_TOTAL_STEPS} seeding single reaction on comment notification..."
# single reaction on comment notification
attributes = {
  body_markdown: "Single reaction on comment #{rand(100)}",
  user_id: user.id,
  commentable_id: Article.last.id,
  commentable_type: "Article"
}
your_comment = Comment.create!(attributes)

comment_rxn = Reaction.create!(reactable: your_comment, user_id: users[4].id, category: "like")
Notification.send_reaction_notification_without_delay(comment_rxn, user)

puts "6/#{NUM_TOTAL_STEPS} seeding comment moderation notification..."
# comment moderation notification
user.add_role :super_admin
Notifications::Moderation::Send.call(user, Comment.first)

puts "7/#{NUM_TOTAL_STEPS} seeding mention notification..."
# mention notification
mention_comment_attributes = {
  body_markdown: "Cool post @#{user.username}! ##{rand(100)}",
  user_id: users[0].id,
  commentable_id: Article.first.id,
  commentable_type: "Article"
}
mention_comment = Comment.create!(mention_comment_attributes)
Mentions::CreateAll.call(mention_comment)
Notifications::NewMention::Send.call(Mention.first!)

puts "8/#{NUM_TOTAL_STEPS} seeding tag adjustment notification..."
# tag adjustment notification
tag = Tag.find_by(name: "beginners")
users[0].add_role :super_admin
tag_adjustment = TagAdjustment.create!(
  tag_id: tag.id,
  adjustment_type: "removal",
  article_id: your_article.id,
  reason_for_adjustment: "This is not for beginners :(",
  status: "resolved",
  user: users[0],
  tag_name: "beginners"
)
Notifications::TagAdjustmentNotification::Send.call(tag_adjustment)

puts "9/#{NUM_TOTAL_STEPS} seeding new post by user you follow notification..."
# User you follow made a new post notification
user.follow(users[0]) unless user.following?(users[0])
markdown = <<~MARKDOWN
  ---
  title:  #{Faker::Book.title} #{Faker::Lorem.sentence(word_count: 2).chomp('.')}
  published: true
  cover_image: #{Faker::Company.logo}
  tags: beginners, career, computerscience
  ---
​
  #{Faker::Hipster.paragraph(sentence_count: 2)}
  #{Faker::Markdown.random}
  #{Faker::Hipster.paragraph(sentence_count: 2)}
MARKDOWN
followed_user_article = Article.create!(
    body_markdown: markdown,
  featured: true,
  show_comments: true,
  user: users[0],
)
Notifications::NotifiableAction::Send.call(followed_user_article, "Published")

puts "10/#{NUM_TOTAL_STEPS} seeding new post by organization you follow notification..."
# # Organization you follow made a new post notification
seeder.create_if_none(Organization) do
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
org = Organization.last
user.follow(org)
OrganizationMembership.find_or_create_by(user: user[0], organization: org, type_of_user: "admin")

markdown = <<~MARKDOWN
  ---
  title:  #{Faker::Book.title} #{Faker::Lorem.sentence(word_count: 2).chomp('.')}
  published: true
  cover_image: #{Faker::Company.logo}
  tags: beginners, career, computerscience
  ---
​
  #{Faker::Hipster.paragraph(sentence_count: 2)}
  #{Faker::Markdown.random}
  #{Faker::Hipster.paragraph(sentence_count: 2)}
MARKDOWN
followed_org_article = Article.create!(
  body_markdown: markdown,
  featured: true,
  show_comments: true,
  user: org.users.first,
  organization: org,
)
Notifications::NotifiableAction::Send.call(followed_org_article, "Published")

puts "#{NUM_TOTAL_STEPS}/#{NUM_TOTAL_STEPS} seeding milestone notifications..."
# View and reaction milestone notifications
your_article = Article.find_by(user: user)
your_article.update(page_views_count: 1025, public_reactions_count: 65)
Notifications::Milestone::Send.call("View", your_article)
Notifications::Milestone::Send.call("Reaction", your_article)

puts "\n\nNotification seed complete"
