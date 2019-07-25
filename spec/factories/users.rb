FactoryBot.define do
  sequence(:email) { |n| "person#{n}@example.com" }
  sequence(:username) { |n| "username#{n}" }
  sequence(:twitter_username) { |n| "twitter#{n}" }
  sequence(:github_username) { |n| "github#{n}" }

  image = Rack::Test::UploadedFile.new(
    Rails.root.join("spec", "support", "fixtures", "images", "image1.jpeg"),
    "image/jpeg",
  )

  factory :user do
    name               { Faker::Name.name }
    email              { generate :email }
    username           { generate :username }
    profile_image      { image }
    twitter_username   { generate :twitter_username }
    github_username    { generate :github_username }
    summary            { Faker::Lorem.paragraph[0..rand(190)] }
    website_url        { Faker::Internet.url }
    confirmed_at       { Time.current }
    saw_onboarding { true }
    checked_code_of_conduct { true }
    checked_terms_and_conditions { true }
    signup_cta_variant { "navbar_basic" }
    email_digest_periodic { false }

    after(:create) do |user|
      create(:identity, user_id: user.id)
    end

    trait :two_identities do
      after(:create) { |user| create(:identity, user_id: user.id, provider: "twitter") }
    end

    trait :super_admin do
      after(:build) { |user| user.add_role(:super_admin) }
    end

    trait :admin do
      after(:build) { |user| user.add_role(:admin) }
    end

    trait :trusted do
      after(:build) { |user| user.add_role(:trusted) }
    end

    trait :banned do
      after(:build) { |user| user.add_role(:banned) }
    end

    trait :video_permission do
      after(:build) { |user| user.created_at = 3.weeks.ago }
    end

    trait :ignore_after_callback do
      after(:build) do |user|
        user.define_singleton_method(:subscribe_to_mailchimp_newsletter) {}
        # user.class.skip_callback(:validates, :after_create)
      end
    end

    trait :pro do
      after(:build) { |user| user.add_role :pro }
    end

    trait :org_member do
      after(:create) do |user|
        org = create(:organization)
        create(:organization_membership, user_id: user.id, organization_id: org.id, type_of_user: "member")
      end
    end

    trait :org_admin do
      after(:create) do |user|
        org = create(:organization)
        create(:organization_membership, user_id: user.id, organization_id: org.id, type_of_user: "admin")
      end
    end

    trait :with_article do
      after(:create) do |user|
        create(:article, user_id: user.id)
        user.update(articles_count: 1)
      end
    end

    trait :with_only_comment do
      after(:create) do |user|
        other_user = create(:user)
        article = create(:article, user_id: other_user.id)
        create(:comment, user_id: user.id, commentable_id: article.id)
        user.update(comments_count: 1)
      end
    end

    trait :with_article_and_comment do
      after(:create) do |user|
        article = create(:article, user_id: user.id)
        create(:comment, user_id: user.id, commentable_id: article.id)
        user.update(articles_count: 1, comments_count: 1)
      end
    end
  end
end
