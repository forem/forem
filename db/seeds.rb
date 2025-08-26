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
Settings::Authentication.allow_email_password_registration = true

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
      name: Faker::Company.name,
      summary: Faker::Company.bs,
      profile_image: logo = Rails.root.join("app/assets/images/#{rand(1..40)}.png").open,
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
  roles = %i[trusted]

  num_users.times do |i|
    fname = Faker::Name.unique.first_name
    # Including "\\:/" to help with identifying local issues with
    # character escaping.
    lname = Faker::Name.unique.last_name
    name = [fname, "\"The #{fname}\"", lname, " \\:/"].join(" ")
    username = "#{fname} #{lname}"

    user = User.create!(
      name: name,
      profile_image: Rails.root.join("app/assets/images/#{rand(1..40)}.png").open,
      # Twitter username should be always ASCII
      twitter_username: Faker::Internet.username(specifier: username.transliterate),
      # Emails limited to 50 characters
      email: Faker::Internet.email(
        name: username.transliterate, separators: "+", domain: Faker::Internet.domain_word.first(20),
      ),
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

    omniauth_info = OmniAuth::AuthHash::InfoHash.new(
      first_name: fname,
      last_name: lname,
      location: "location,state,country",
      name: name,
      nickname: user.username,
      email: user.email,
      verified: true,
    )

    omniauth_extra_info = OmniAuth::AuthHash::InfoHash.new(
      raw_info: OmniAuth::AuthHash::InfoHash.new(
        email: user.email,
        first_name: fname,
        gender: "female",
        id: "123456",
        last_name: lname,
        link: "http://www.facebook.com/url&#8221",
        lang: "fr",
        locale: "en_US",
        name: name,
        timezone: 5.5,
        updated_time: "2012-06-08T13:09:47+0000",
        username: user.username,
        verified: true,
        followers_count: 100,
        friends_count: 1000,
        created_at: "2017-06-08T13:09:47+0000",
      ),
    )

    omniauth_basic_info = {
      uid: SecureRandom.hex(3),
      info: omniauth_info,
      extra: omniauth_extra_info,
      credentials: {
        token: SecureRandom.hex,
        secret: SecureRandom.hex
      }
    }.freeze

    info = omniauth_basic_info[:info].merge(
      image: "https://dummyimage.com/400x400_normal.jpg",
      urls: { "Twitter" => "https://example.com" },
    )

    extra = omniauth_basic_info[:extra].merge(
      access_token: "value",
    )

    auth_dump = OmniAuth::AuthHash.new(
      omniauth_basic_info.merge(
        provider: "twitter",
        info: info,
        extra: extra,
      ),
    )

    Identity.create!(
      provider: "twitter",
      uid: i.to_s,
      token: i.to_s,
      secret: i.to_s,
      user: user,
      auth_data_dump: auth_dump,
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
    name: "Admin \"The \\:/ Administrator\" McAdmin",
    email: "admin@forem.local",
    username: "Admin_McAdmin",
    profile_image: Rails.root.join("app/assets/images/#{rand(1..40)}.png").open,
    confirmed_at: Time.current,
    registered_at: Time.current,
    password: "password",
    password_confirmation: "password",
  )

  user.profile.update(
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    website_url: Faker::Internet.url,
  )

  user.add_role(:super_admin)
  user.add_role(:trusted)
  user.add_role(:tech_admin)
end

Users::CreateMascotAccount.call unless Settings::General.mascot_user_id

##############################################################################

seeder.create_if_none(Badge) do
  5.times do
    Badge.create!(
      title: "#{Faker::Lorem.word} #{rand(100)}",
      description: Faker::Lorem.sentence,
      badge_image: Rails.root.join("app/assets/images/#{rand(1..40)}.png").open,
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

seeder.create_if_none(Tag) do
  tags = %w[beginners career computerscience git go
            java javascript linux productivity python security webdev]

  tags.each do |tag_name|
    Tag.create!(
      name: tag_name,
      short_summary: Faker::Lorem.sentence,
      bg_color_hex: Faker::Color.hex_color,
      text_color_hex: Faker::Color.hex_color,
      supported: true,
      badge: Badge.order(Arel.sql("RANDOM()")).limit(1).take,
    )
  end
end

##############################################################################

num_articles = 25 * SEEDS_MULTIPLIER

seeder.create_if_none(Article, num_articles) do
  user_ids = User.all.ids
  public_categories = %w[like unicorn]

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

    article = Article.create!(
      body_markdown: markdown,
      featured: i.zero?, # only feature the first article,
      show_comments: true,
      user_id: User.order(Arel.sql("RANDOM()")).first.id,
    )

    Random.random_number(10).times do |_t|
      article.reactions.create(
        user_id: user_ids.sample,
        category: public_categories.sample,
      )
    end

    article.sync_reactions_count
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
      published: true,
      featured: true
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
      published: true,
      featured: true
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
      published: true,
      featured: true
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
      published: true,
      featured: true
    },
  ]

  podcast_objects.each do |attributes|
    podcast = Podcast.create!(attributes)
    Podcasts::GetEpisodesWorker.perform_async("podcast_id" => podcast.id)
  end
end
##############################################################################

seeder.create_if_none(Broadcast) do
  broadcast_messages = {
    set_up_profile: I18n.t("broadcast.welcome.set_up_profile"),
    welcome_thread: I18n.t("broadcast.welcome.welcome_thread"),
    twitter_connect: I18n.t("broadcast.connect.twitter"),
    facebook_connect: I18n.t("broadcast.connect.facebook"),
    github_connect: I18n.t("broadcast.connect.github"),
    google_oauth2_connect: I18n.t("broadcast.connect.google"),
    apple_connect: I18n.t("broadcast.connect.apple"),
    customize_feed: I18n.t("broadcast.welcome.customize_feed"),
    customize_experience: I18n.t("broadcast.welcome.customize_experience"),
    start_discussion: I18n.t("broadcast.welcome.start_discussion"),
    ask_question: I18n.t("broadcast.welcome.ask_question"),
    discuss_and_ask: I18n.t("broadcast.welcome.discuss_and_ask"),
    download_app: I18n.t("broadcast.welcome.download_app")
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

seeder.create_if_none(HtmlVariant) do
  HtmlVariant.create!(
    name: rand(100).to_s,
    group: "badge_landing_page",
    html: rand(1000).to_s,
    published: true,
    approved: true,
    user_id: User.first.id,
  )
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

##############################################################################

seeder.create_if_none(Billboard) do
  Billboard::ALLOWED_PLACEMENT_AREAS.each do |placement_area|
    Billboard.create!(
      name: "#{Faker::Lorem.word} #{placement_area}",
      body_markdown: Faker::Lorem.sentence,
      published: true,
      approved: true,
      placement_area: placement_area,
    )
  end

  segment = AudienceSegment.create!(type_of: :manual)
  Billboard.create!(
    name: "#{Faker::Lorem.word} (Manually Managed Audience)",
    body_markdown: Faker::Lorem.sentence,
    published: true,
    approved: true,
    placement_area: Billboard::ALLOWED_PLACEMENT_AREAS.sample,
    audience_segment: segment,
  )
end

##############################################################################

# change locale to en to work around non-ascii slug problem
loc = I18n.locale
Faker::Config.locale = "en"
seeder.create_if_none(Page) do
  5.times do
    Page.create!(
      title: Faker::Hacker.say_something_smart,
      body_markdown: Faker::Markdown.random,
      slug: Faker::Internet.slug,
      description: Faker::Books::Dune.quote,
      template: %w[contained full_within_layout nav_bar_included].sample,
    )
  end
end
Faker::Config.locale = loc

##############################################################################

seeder.create_if_none(Survey) do
  # Marvel Movie Preferences Survey (Single Choice)
  marvel_survey = Survey.create!(
    title: "Marvel Movie Preferences",
    active: true,
    display_title: true,
  )

  # Poll 1: Favorite Marvel Movie (Single Choice)
  Poll.create!(
    prompt_markdown: "What is your favorite Marvel movie?",
    article_id: nil,
    survey_id: marvel_survey.id,
    type_of: :single_choice,
    poll_options_input_array: [
      "Avengers: Endgame",
      "Black Panther",
      "Spider-man: No Way Home",
      "Guardians of the Galaxy",
    ],
    poll_options_supplementary_text_array: [
      "The epic conclusion to the Infinity Saga",
      "Groundbreaking representation and storytelling",
      "Multiverse adventure with emotional depth",
      "Space adventure with heart and humor",
    ],
  )

  # Poll 2: Preferred Marvel Hero (Single Choice)
  Poll.create!(
    prompt_markdown: "Who is your preferred Marvel hero?",
    article_id: nil,
    survey_id: marvel_survey.id,
    type_of: :single_choice,
    poll_options_input_array: [
      "Iron Man",
      "Captain America",
      "Thor",
      "Doctor Strange",
    ],
    poll_options_supplementary_text_array: [
      "Genius billionaire playboy philanthropist",
      "The first Avenger, symbol of hope",
      "God of Thunder with cosmic powers",
      "Master of the Mystic Arts",
    ],
  )

  # Poll 3: Most Compelling Villain (Single Choice)
  Poll.create!(
    prompt_markdown: "Who is the most compelling Marvel villain?",
    article_id: nil,
    survey_id: marvel_survey.id,
    type_of: :single_choice,
    poll_options_input_array: [
      "Thanos",
      "Loki",
      "Erik Killmonger",
      "Wanda Maximoff / Scarlet Witch",
    ],
    poll_options_supplementary_text_array: [
      "The Mad Titan with a twisted sense of purpose",
      "The God of Mischief with complex motivations",
      "Villain with understandable grievances",
      "Hero turned villain through grief and trauma",
    ],
  )

  # Poll 4: Favorite Marvel Team (Single Choice)
  Poll.create!(
    prompt_markdown: "Which is your favorite Marvel team?",
    article_id: nil,
    survey_id: marvel_survey.id,
    type_of: :single_choice,
    poll_options_input_array: [
      "The Avengers",
      "Guardians of the Galaxy",
      "The Revengers (from Thor: Ragnarok)",
      "The X-Men",
    ],
    poll_options_supplementary_text_array: [
      "Earth's mightiest heroes",
      "Cosmic misfits turned heroes",
      "Thor's temporary team of gladiators",
      "Mutant heroes fighting for coexistence",
    ],
  )

  # Poll 5: Infinity Stone Choice (Single Choice)
  Poll.create!(
    prompt_markdown: "If you could wield one Infinity Stone, which would you choose?",
    article_id: nil,
    survey_id: marvel_survey.id,
    type_of: :single_choice,
    poll_options_input_array: [
      "The Time Stone (to control time)",
      "The Space Stone (for teleportation)",
      "The Reality Stone (to alter reality)",
      "The Power Stone (for immense strength)",
    ],
    poll_options_supplementary_text_array: [
      "Green stone - manipulate time flow",
      "Blue stone - instant travel anywhere",
      "Red stone - reshape reality itself",
      "Purple stone - unlimited physical power",
    ],
  )

  # Tech Stack Preferences Survey (Multiple Choice)
  tech_survey = Survey.create!(
    title: "Tech Stack Preferences",
    active: true,
    display_title: true,
  )

  # Poll 1: Programming Languages (Multiple Choice)
  Poll.create!(
    prompt_markdown: "Which programming languages do you use regularly? (Select all that apply)",
    article_id: nil,
    survey_id: tech_survey.id,
    type_of: :multiple_choice,
    poll_options_input_array: [
      "JavaScript/TypeScript",
      "Python",
      "Ruby",
      "Java",
      "C#",
      "Go",
      "Rust",
      "PHP",
    ],
  )

  # Poll 2: Frontend Frameworks (Multiple Choice)
  Poll.create!(
    prompt_markdown: "Which frontend frameworks have you worked with? (Select all that apply)",
    article_id: nil,
    survey_id: tech_survey.id,
    type_of: :multiple_choice,
    poll_options_input_array: [
      "React",
      "Vue.js",
      "Angular",
      "Svelte",
      "Ember.js",
      "Backbone.js",
    ],
  )

  # Poll 3: Database Technologies (Multiple Choice)
  Poll.create!(
    prompt_markdown: "Which database technologies do you use? (Select all that apply)",
    article_id: nil,
    survey_id: tech_survey.id,
    type_of: :multiple_choice,
    poll_options_input_array: %w[
      PostgreSQL
      MySQL
      MongoDB
      Redis
      SQLite
      Elasticsearch
      Cassandra
    ],
  )

  # Developer Experience Survey (Scale)
  dev_experience_survey = Survey.create!(
    title: "Developer Experience Assessment",
    active: true,
    display_title: true,
  )

  # Poll 1: Code Review Experience (Scale)
  Poll.create!(
    prompt_markdown: "How would you rate your experience with code reviews?",
    article_id: nil,
    survey_id: dev_experience_survey.id,
    type_of: :scale,
    poll_options_input_array: %w[1 2 3 4 5],
    poll_options_supplementary_text_array: [
      "Not at all satisfied",
      nil,
      nil,
      nil,
      "Extremely satisfied",
    ],
  )

  # Poll 2: Documentation Quality (Scale)
  Poll.create!(
    prompt_markdown: "How would you rate the quality of documentation in your current project?",
    article_id: nil,
    survey_id: dev_experience_survey.id,
    type_of: :scale,
    poll_options_input_array: %w[1 2 3 4 5],
    poll_options_supplementary_text_array: [
      "Very poor",
      nil,
      nil,
      nil,
      "Excellent",
    ],
  )

  # Poll 3: Team Collaboration (Scale)
  Poll.create!(
    prompt_markdown: "How would you rate team collaboration in your current role?",
    article_id: nil,
    survey_id: dev_experience_survey.id,
    type_of: :scale,
    poll_options_input_array: %w[1 2 3 4 5],
    poll_options_supplementary_text_array: [
      "Very difficult",
      nil,
      nil,
      nil,
      "Very smooth",
    ],
  )

  # Poll 4: Work-Life Balance (Scale)
  Poll.create!(
    prompt_markdown: "How would you rate your work-life balance?",
    article_id: nil,
    survey_id: dev_experience_survey.id,
    type_of: :scale,
    poll_options_input_array: %w[1 2 3 4 5],
    poll_options_supplementary_text_array: [
      "Poor balance",
      nil,
      nil,
      nil,
      "Perfect balance",
    ],
  )

  # Poll 5: Detailed Satisfaction (Scale with more than 10 options - vertical layout)
  Poll.create!(
    prompt_markdown: "Rate your satisfaction with each aspect of your development environment (1-15 scale)",
    article_id: nil,
    survey_id: dev_experience_survey.id,
    type_of: :scale,
    poll_options_input_array: %w[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15],
  )

  # Mixed Survey (All Types)
  mixed_survey = Survey.create!(
    title: "Mixed Poll Types Demo",
    active: true,
    display_title: true,
  )

  # Poll 1: Single Choice
  Poll.create!(
    prompt_markdown: "What is your primary development environment?",
    article_id: nil,
    survey_id: mixed_survey.id,
    type_of: :single_choice,
    poll_options_input_array: [
      "VS Code",
      "IntelliJ IDEA",
      "Vim/Neovim",
      "Sublime Text",
      "Atom",
    ],
    poll_options_supplementary_text_array: [
      "Microsoft's popular open-source editor",
      "JetBrains' powerful IDE suite",
      "Terminal-based editor with modal editing",
      "Fast and lightweight text editor",
      "GitHub's hackable text editor",
    ],
  )

  # Poll 2: Multiple Choice
  Poll.create!(
    prompt_markdown: "Which development practices do you follow? (Select all that apply)",
    article_id: nil,
    survey_id: mixed_survey.id,
    type_of: :multiple_choice,
    poll_options_input_array: [
      "Test-Driven Development (TDD)",
      "Continuous Integration/Deployment",
      "Code Reviews",
      "Pair Programming",
      "Agile/Scrum",
      "DevOps Practices",
    ],
  )

  # Poll 3: Scale
  Poll.create!(
    prompt_markdown: "Rate your satisfaction with your current development tools",
    article_id: nil,
    survey_id: mixed_survey.id,
    type_of: :scale,
    poll_options_input_array: %w[1 2 3 4 5],
    poll_options_supplementary_text_array: [
      "Very dissatisfied",
      nil,
      nil,
      nil,
      "Very satisfied",
    ],
  )

  # Poll 4: Text Input
  Poll.create!(
    prompt_markdown: "What's the biggest challenge you face in your development workflow?",
    article_id: nil,
    survey_id: mixed_survey.id,
    type_of: :text_input,
    poll_options_input_array: [],
  )

  # Feedback Survey (Text Input Focus)
  feedback_survey = Survey.create!(
    title: "Developer Feedback Survey",
    active: true,
    display_title: true,
  )

  # Poll 1: Text Input - General Feedback
  Poll.create!(
    prompt_markdown: "What features would you like to see added to your development tools?",
    article_id: nil,
    survey_id: feedback_survey.id,
    type_of: :text_input,
    poll_options_input_array: [],
  )

  # Poll 2: Text Input - Pain Points
  Poll.create!(
    prompt_markdown: "Describe the most frustrating part of your current development process:",
    article_id: nil,
    survey_id: feedback_survey.id,
    type_of: :text_input,
    poll_options_input_array: [],
  )

  # Poll 3: Scale - Overall Satisfaction
  Poll.create!(
    prompt_markdown: "How satisfied are you with your current development setup?",
    article_id: nil,
    survey_id: feedback_survey.id,
    type_of: :scale,
    poll_options_input_array: %w[1 2 3 4 5 6 7 8 9 10],
  )
end

##############################################################################

# Create articles with survey tags
seeder.create_if_none(Article) do
  users_in_random_order = User.order(Arel.sql("RANDOM()"))
  users = users_in_random_order.to_a

  # Article with Marvel survey
  user = users.first
  Article.create!(
    user: user,
    title: "Marvel Movie Discussion",
    body_markdown: "Let's discuss our favorite Marvel movies and characters!\n\n{% survey 1 %}",
    published: true,
    originally_published_at: Time.current,
    tag_list: %w[marvel movies discussion],
  )

  # Article with Tech survey
  user = users.second
  Article.create!(
    user: user,
    title: "Tech Stack Discussion",
    body_markdown: "What's your preferred tech stack? Let's share our experiences!\n\n{% survey 2 %}",
    published: true,
    originally_published_at: Time.current,
    tag_list: %w[tech programming discussion],
  )

  # Article with Developer Experience survey
  user = users.third
  Article.create!(
    user: user,
    title: "Developer Experience Survey",
    body_markdown: "How's your developer experience? Let's assess our current situation.\n\n{% survey 3 %}",
    published: true,
    originally_published_at: Time.current,
    tag_list: %w[developer-experience survey discussion],
  )

  # Article with Mixed survey
  user = users.fourth
  Article.create!(
    user: user,
    title: "Mixed Poll Types Demo",
    body_markdown: "This article demonstrates all three poll types: single choice, multiple choice, scale, and text input.\n\n{% survey 4 %}",
    published: true,
    originally_published_at: Time.current,
    tag_list: %w[demo polls survey],
  )

  # Article with Feedback survey
  user = users.fifth
  Article.create!(
    user: user,
    title: "Developer Feedback Survey",
    body_markdown: "Share your thoughts on development tools and processes. We'd love to hear your feedback!\n\n{% survey 5 %}",
    published: true,
    originally_published_at: Time.current,
    tag_list: %w[feedback development survey],
  )
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
