FactoryBot.define do
  sequence(:title) { |n| "#{Faker::Book.title}#{n}" }

  factory :article do
    published_at { Time.current }

    transient do
      title { generate :title }
      published { true }
      date { "01/01/2015" }
      tags { "javascript, html, discuss" }
      canonical_url { Faker::Internet.url }
      with_canonical_url { false }
      with_main_image { true }
      with_date { false }
      with_tags { true }
      with_hr_issue { false }
      with_tweet_tag { false }
      with_user_subscription_tag { false }
      with_title { true }
      with_collection { nil }
    end
    co_author_ids { [] }
    association :user, factory: :user, strategy: :create
    description { Faker::Hipster.paragraph(sentence_count: 1)[0..100] }
    main_image    { with_main_image ? Faker::Avatar.image : nil }
    experience_level_rating { rand(4..6) }
    body_markdown do
      <<~HEREDOC
        ---
        title: #{title if with_title}
        published: #{published}
        tags: #{tags if with_tags}
        date: #{date if with_date}
        series: #{with_collection&.slug if with_collection}
        canonical_url: #{canonical_url if with_canonical_url}
        ---

        #{Faker::Hipster.paragraph(sentence_count: 2)}
        #{'{% tweet 1018911886862057472 %}' if with_tweet_tag}
        #{'{% user_subscription CTA text %}' if with_user_subscription_tag}
        #{Faker::Hipster.paragraph(sentence_count: 1)}
        #{"\n\n---\n\n something \n\n---\n funky in the code? \n---\n That's nice" if with_hr_issue}
      HEREDOC
    end
  end

  trait :video do
    after(:build) do |article|
      article.video = "https://s3.amazonaws.com/dev-to-input-v0/video-upload__2d7dc29e39a40c7059572bca75bb646b"
      article.save
    end
  end

  trait :with_notification_subscription do
    after(:create) do |article|
      create(:notification_subscription, user_id: article.user_id, notifiable: article)
    end
  end

  trait :with_user_subscription_tag_role_user do
    after(:build) { |article| article.user.add_role(:restricted_liquid_tag, LiquidTags::UserSubscriptionTag) }
  end

  trait :with_discussion_lock do
    after(:create) { |article| create(:discussion_lock, locking_user_id: article.user_id, article_id: article.id) }
  end
end
