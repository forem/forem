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
      past_published_at { Time.current }
    end

    co_author_ids { [] }
    association :user, factory: :user, strategy: :create
    description { Faker::Hipster.paragraph(sentence_count: 1)[0..100] }
    main_image    do
      if with_main_image
        URL.url(ActionController::Base.helpers.asset_path("#{rand(1..40)}.png"))
      end
    end

    experience_level_rating { rand(4..6) }
    # The tags property in the markdown is a bit of a hack, and this entire factory needs refactoring.
    # In the Tagglable spec we want to extract some common scopes from the article and display ad
    # models and test them, hence we want to pass through the tag_list property.
    # However, the body_markdown caters for the way that we associate tags for the v1 editor.
    # Hence, in this test we default to the transient with_tags being set to true, but if we pass a tag_list through
    # then we're making the assumption that it is the v2 editor and we do not want the tags on the body markdown.
    # Ideally, we want to create a completely different body_markdown without the frontmatter depending on the version
    # of the editor since we pass through different JSON based on the editor.
    body_markdown do
      <<~HEREDOC
        ---
        title: #{title if with_title}
        published: #{published}
        #{"tags: #{tags}" if with_tags && tag_list.blank?}
        date: #{date if with_date}
        series: #{with_collection&.slug}
        canonical_url: #{canonical_url if with_canonical_url}
        #{"cover_image: #{Faker::Avatar.image}" if with_main_image && main_image_from_frontmatter}
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

  # NOTE: [@lightalloy] This trait is used to create articles published in the past (with past published_at)
  # we can't do it directly because of the validation Article#has_correct_published_at?
  # TODO: [@lightalloy] Remove the trait and its usage when has_correct_published_at? will be removed
  trait :past do
    after(:create) do |article, evaluator|
      article.update_column(:published_at, evaluator.past_published_at)
    end
  end
end
