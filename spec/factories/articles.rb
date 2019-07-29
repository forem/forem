FactoryBot.define do
  factory :article do
    transient do
      title { Faker::Book.title + rand(100).to_s }
      published { true }
      date { "01/01/2015" }
      tags { Faker::Hipster.words(4).join(", ") }
      canonical_url { Faker::Internet.url }
      with_canonical_url { false }
      with_date { false }
      with_tags { true }
      with_hr_issue { false }
      with_tweet_tag { false }
      with_title { true }
      with_collection { nil }
    end
    association :user, factory: :user, strategy: :create
    description   { Faker::Hipster.paragraph(1)[0..100] }
    main_image    { Faker::Avatar.image }
    language { "en" }
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

        #{Faker::Hipster.paragraph(2)}
        #{'{% tweet 1018911886862057472%}' if with_tweet_tag}
        #{Faker::Hipster.paragraph(1)}
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
end
