return unless Rails.env.test? && ENV["E2E"].present?

# NOTE: when adding new data, please use the Seeder class to ensure the seed tasks
# stays idempotent.
require Rails.root.join("app/lib/seeder")

seeder = Seeder.new

##############################################################################
# Default development settings are different from production scenario

Settings::UserExperience.public = true
Settings::General.waiting_on_first_user = false
Settings::Authentication.allow_email_password_registration = true

##############################################################################

# NOTE: @citizen428 For the time being we want all current DEV profile fields.
# The CSV import is idempotent by itself, since it uses find_or_create_by.
seeder.create("Creating DEV profile fields") do
  dev_fields_csv = Rails.root.join("lib/data/dev_profile_fields.csv")
  ProfileFields::ImportFromCsv.call(dev_fields_csv)
end

##############################################################################

seeder.create_if_doesnt_exist(User, "email", "admin@forem.local") do
  user = User.create!(
    name: "Admin McAdmin",
    email: "admin@forem.local",
    username: "Admin_McAdmin",
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )

  user.profile.update({
                        summary: "Admin user summary",
                        employment_title: "Software developer",
                        location: "Edinburgh",
                        education: "University of Life"
                      })
  user.add_role(:super_admin)
  user.add_role(:single_resource_admin, Config)
  user.add_role(:trusted)
end

admin_user = User.find_by(email: "admin@forem.local")

##############################################################################

seeder.create_if_doesnt_exist(User, "email", "trusted-user-1@forem.local") do
  user = User.create!(
    name: "Trusted User 1",
    email: "trusted-user-1@forem.local",
    username: "trusted_user_1",
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )

  user.add_role(:trusted)
end

##############################################################################

seeder.create_if_none(Organization) do
  organization = Organization.create!(
    name: "Bachmanity",
    summary: Faker::Company.bs,
    remote_profile_image_url: logo = Faker::Company.logo,
    nav_image: logo,
    url: Faker::Internet.url,
    slug: "bachmanity",
  )

  OrganizationMembership.create!(
    user_id: admin_user.id,
    organization_id: organization.id,
    type_of_user: "admin",
  )
end

##############################################################################

seeder.create_if_doesnt_exist(User, "email", "change-password-user@forem.com") do
  user = User.create!(
    name: "Change Password User",
    email: "change-password-user@forem.com",
    username: "changepassworduser",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )
  user
end

##############################################################################

seeder.create_if_doesnt_exist(User, "email", "article-editor-v1-user@forem.com") do
  user = User.create!(
    name: "Article Editor v1 User",
    email: "article-editor-v1-user@forem.local",
    username: "article_editor_v1_user",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.setting.update(editor_version: "v1")
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )
  user
end

##############################################################################

seeder.create_if_doesnt_exist(User, "email", "article-editor-v2-user@forem.com") do
  user = User.create!(
    name: "Article Editor v2 User",
    email: "article-editor-v2-user@forem.local",
    username: "article_editor_v2_user",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )
  user
end

##############################################################################

chat_user_1 = seeder.create_if_doesnt_exist(User, "email", "chat-user-1@forem.local") do
  user = User.create!(
    name: "Chat user 1",
    email: "chat-user-1@forem.local",
    username: "chat_user_1",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )
  user
end

##############################################################################

chat_user_2 = seeder.create_if_doesnt_exist(User, "email", "chat-user-2@forem.local") do
  user = User.create!(
    name: "Chat user 2",
    email: "chat-user-2@forem.local",
    username: "chat_user_2",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )
  user
end

##############################################################################
seeder.create_if_doesnt_exist(User, "email", "notifications-user@forem.com") do
  user = User.create!(
    name: "Notifications User",
    email: "notifications-user@forem.local",
    username: "notifications_user",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
  user.notification_setting.update(
    email_comment_notifications: false,
    email_follower_notifications: false,
  )

  follow = admin_user.follows.create!(followable: user)
  Notification.send_new_follower_notification_without_delay(follow)
end

##############################################################################

seeder.create_if_doesnt_exist(ChatChannel, "channel_name", "test chat channel") do
  channel = ChatChannel.create(
    channel_type: "open",
    channel_name: "test chat channel",
    slug: "test-chat-channel",
    last_message_at: 1.week.ago,
    status: "active",
  )

  channel.invite_users(users: [chat_user_1, chat_user_2])

  Message.create(message_markdown: "Test message from chat_user_1", user_id: chat_user_1.id,
                 chat_channel_id: channel.id)
end

##############################################################################

seeder.create_if_none(NavigationLink) do
  protocol = ApplicationConfig["APP_PROTOCOL"].freeze
  domain = Rails.application&.initialized? ? Settings::General.app_domain : ApplicationConfig["APP_DOMAIN"]
  base_url = "#{protocol}#{domain}".freeze
  reading_icon = File.read(Rails.root.join("app/assets/images/twemoji/drawer.svg")).freeze

  NavigationLink.create!(
    name: "Reading List",
    url: "#{base_url}/readinglist",
    icon: reading_icon,
    display_only_when_signed_in: true,
    position: 0,
    section: :default,
  )
end

##############################################################################

seeder.create_if_doesnt_exist(NavigationLink, "url", "/contact") do
  icon = '<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'\
         '<path d="M12 1l9.5 5.5v11L12 23l-9.5-5.5v-11L12 1zm0 2.311L4.5 7.653v8.694l7.5 4.342'\
         '7.5-4.342V7.653L12 3.311zM12 16a4 4 0 110-8 4 4 0 010 8zm0-2a2 2 0 100-4 2 2 0 000 4z"/>'\
         '</svg>'
  6.times do |i|
    NavigationLink.create!(
      name: "Nav link #{i}",
      position: i + 1,
      url: "/contact",
      icon: icon,
      section: :default,
    )
  end
end

##############################################################################

seeder.create_if_doesnt_exist(Article, "title", "Test article") do
  markdown = <<~MARKDOWN
    ---
    title:  Test article
    published: true
    cover_image: #{Faker::Company.logo}
    ---
    #{Faker::Hipster.paragraph(sentence_count: 2)}
    #{Faker::Markdown.random}
    #{Faker::Hipster.paragraph(sentence_count: 2)}
  MARKDOWN
  article = Article.create(
    body_markdown: markdown,
    featured: true,
    show_comments: true,
    user_id: admin_user.id,
  )

  comment_attributes = {
    body_markdown: Faker::Hipster.paragraph(sentence_count: 1),
    user_id: admin_user.id,
    commentable_id: article.id,
    commentable_type: "Article"
  }

  Comment.create!(comment_attributes)
end

##############################################################################

seeder.create_if_doesnt_exist(Article, "title", "Organization test article") do
  markdown = <<~MARKDOWN
    ---
    title:  Organization test article
    published: true
    cover_image: #{Faker::Company.logo}
    ---
    #{Faker::Hipster.paragraph(sentence_count: 2)}
    #{Faker::Markdown.random}
    #{Faker::Hipster.paragraph(sentence_count: 2)}
  MARKDOWN
  Article.create(
    body_markdown: markdown,
    featured: true,
    show_comments: true,
    user_id: admin_user.id,
    organization_id: Organization.first.id,
  )
end

##############################################################################

seeder.create_if_none(ListingCategory) do
  ListingCategory.create!(
    slug: "cfp",
    cost: 1,
    name: "Conference CFP",
    rules: "Currently open for proposals, with link to form.",
  )
end

##############################################################################

seeder.create_if_none(Listing) do
  Credit.add_to(admin_user, rand(100))

  Listing.create!(
    user: admin_user,
    title: "Listing title",
    body_markdown: Faker::Markdown.random,
    location: Faker::Address.city,
    organization_id: admin_user.organizations.first&.id,
    listing_category_id: ListingCategory.first.id,
    contact_via_connect: true,
    published: true,
    originally_published_at: Time.current,
    bumped_at: Time.current,
    tag_list: Tag.order(Arel.sql("RANDOM()")).first(2).pluck(:name),
  )
end

##############################################################################

seeder.create_if_none(Tag) do
  tag = Tag.create!(
    name: "tag1",
    bg_color_hex: Faker::Color.hex_color,
    text_color_hex: Faker::Color.hex_color,
    supported: true,
  )

  admin_user.add_role(:tag_moderator, tag)
end

# Show the tag in the sidebar
Settings::General.sidebar_tags = %i[tag1]

##############################################################################

seeder.create_if_none(Badge) do
  Badge.create!(
    title: "#{Faker::Lorem.word} #{rand(100)}",
    description: Faker::Lorem.sentence,
    badge_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
  )

  admin_user.badge_achievements.create!(
    badge: Badge.first,
    rewarding_context_message_markdown: Faker::Markdown.random,
  )
end

##############################################################################

seeder.create_if_none(Page) do
  2.times do |t|
    Page.create!(
      slug: "#{Faker::Lorem.word}-#{t}",
      body_html: "<p>#{Faker::Hipster.paragraph(sentence_count: 2)}</p>",
      title: "#{Faker::Lorem.word} #{rand(100)}",
      description: "A test page",
      is_top_level_path: true,
      landing_page: false,
    )
  end
end
