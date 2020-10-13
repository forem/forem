# Notification seed file, to mock notifications for a specific user (ideally yourself).
# To run the command, run:
# rails db:seed:notifications USERNAME='your_username'
# if no username is given, the script will use the last user

NUM_TOTAL_STEPS = 11

user = User.find_by(username: ENV["USERNAME"]) || User.last

puts "1/#{NUM_TOTAL_STEPS} seeding follower notifications..."
# three followers notification
User.first(3).each do |follower|
  follow = Follow.create!(followable: user, follower: follower)
  Notification.send_new_follower_notification_without_delay(follow)
end

# two followers notification
follow = User.fourth.follow(user)
User.fifth.follow(user)
Notification.create!(
  notifiable: follow,
  action: "Follow",
  user: user,
  json_data: {
    user: Notifications.user_data(User.fourth),
    aggregated_siblings: [
      Notifications.user_data(User.fourth),
      Notifications.user_data(User.fifth)
    ]
  }
)

# one follower notification
follow = User.find(6).follow(user)
Notification.create!(
  notifiable: follow,
  action: "Follow",
  user: user,
  json_data: {
    user: Notifications.user_data(User.find(6)),
    aggregated_siblings: [
      Notifications.user_data(User.find(6))
    ]
  }
)

puts "2/#{NUM_TOTAL_STEPS} seeding badge achievement notification.."
# badge achievement notification
BadgeAchievement.last.update(user_id: user.id)
Notifications::NewBadgeAchievement::Send.call(BadgeAchievement.last)

puts "3/#{NUM_TOTAL_STEPS} seeding reaction on article notifications..."
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

User.first(3).each do |reactor|
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
double_rxns = User.where(id: [4,5]).map do |reactor|
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
rxn = Reaction.create!(reactable: single_rxn_article, user: User.find(6), category: "like")
Notification.create!(
  user: user,
  action: "Reaction",
  notifiable: single_rxn_article,
  json_data: {
    user: Notifications.user_data(User.find(6)),
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

puts "4/#{NUM_TOTAL_STEPS} seeding single reaction on comment notification..."
# single reaction on comment notification
attributes = {
  body_markdown: "Single reaction on comment #{rand(100)}",
  user_id: user.id,
  commentable_id: Article.last.id,
  commentable_type: "Article"
}
your_comment = Comment.create!(attributes)

comment_rxn = Reaction.create!(reactable: your_comment, user_id: 5, category: "like")
Notification.send_reaction_notification_without_delay(comment_rxn, user)

puts "5/#{NUM_TOTAL_STEPS} seeding comment moderation notification..."
# comment moderation notification
user.add_role :super_admin
Notifications::Moderation::Send.call(user, Comment.first)

puts "6/#{NUM_TOTAL_STEPS} seeding mention notification..."
# mention notification
mention_comment_attributes = {
  body_markdown: "Cool post @#{user.username}! ##{rand(100)}",
  user_id: User.first.id,
  commentable_id: Article.first.id,
  commentable_type: "Article"
}
mention_comment = Comment.create!(mention_comment_attributes)
Mentions::CreateAll.call(mention_comment)
Notifications::NewMention::Send.call(Mention.first!)

puts "7/#{NUM_TOTAL_STEPS} seeding tag adjustment notification..."
# tag adjustment notification
tag = Tag.find_by(name: "beginners")
User.first.add_role :super_admin
tag_adjustment = TagAdjustment.create!(
  tag_id: tag.id,
  adjustment_type: "removal",
  article_id: your_article.id,
  reason_for_adjustment: "This is not for beginners :(",
  status: "resolved",
  user: User.first,
  tag_name: "beginners"
)
Notifications::TagAdjustmentNotification::Send.call(tag_adjustment)

puts "8/#{NUM_TOTAL_STEPS} seeding new post by user you follow notification..."
# User you follow made a new post notification
user.follow(User.first)
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
  user: User.first,
)
Notifications::NotifiableAction::Send.call(followed_user_article, "Published")

puts "9/#{NUM_TOTAL_STEPS} seeding new post by organization you follow notification..."
# Organization you follow made a new post notification
user.follow(Organization.first)
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
  user: Organization.first.users.first,
)
Notifications::NotifiableAction::Send.call(followed_org_article, "Published")

puts "10/#{NUM_TOTAL_STEPS} seeding milestone notifications..."
# View and reaction milestone notifications
your_article = user.articles.last
your_article.update(page_views_count: 1025, public_reactions_count: 65)
Notifications::Milestone::Send.call("View", your_article)
Notifications::Milestone::Send.call("Reaction", your_article)

puts "#{NUM_TOTAL_STEPS}/#{NUM_TOTAL_STEPS} seeding welcome notification..."
Notifications::WelcomeNotification::Send.call(user.id, Broadcast.first)

puts "Notification seed complete"
