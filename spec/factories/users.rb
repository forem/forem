FactoryBot.define do
  sequence(:email) { |n| "person#{n}@example.com" }
  sequence(:username) { |n| "username#{n}" }
  sequence(:twitter_username) { |n| "twitter#{n}" }
  sequence(:github_username) { |n| "github#{n}" }

  image_path = Rails.root.join("spec/support/fixtures/images/image1.jpeg")

  factory :user do
    name                         { Faker::Name.name }
    email                        { generate :email }
    username                     { generate :username }
    profile_image                { Rack::Test::UploadedFile.new(image_path, "image/jpeg") }
    twitter_username             { generate :twitter_username }
    github_username              { generate :github_username }
    confirmed_at                 { Time.current }
    saw_onboarding               { true }
    checked_code_of_conduct      { true }
    checked_terms_and_conditions { true }
    display_announcements        { true }
    registered_at                { Time.current }
    signup_cta_variant           { "navbar_basic" }
    email_digest_periodic        { false }

    trait :with_identity do
      transient { identities { Authentication::Providers.available } }

      after(:create) do |user, options|
        options.identities.each do |provider|
          auth = OmniAuth.config.mock_auth.fetch(provider.to_sym)
          create(
            :identity,
            user: user, provider: provider, uid: auth.uid, auth_data_dump: auth,
          )
        end
      end
    end

    trait :super_admin do
      after(:build) { |user| user.add_role(:super_admin) }
    end

    trait :admin do
      after(:build) { |user| user.add_role(:admin) }
    end

    trait :single_resource_admin do
      transient do
        resource { nil }
      end

      after(:build) { |user, options| user.add_role(:single_resource_admin, options.resource) }
    end

    trait :tech_admin do
      after(:build) { |user| user.add_role(:tech_admin) }
    end

    trait :restricted_liquid_tag do
      transient do
        resource { nil }
      end

      after(:build) { |user, options| user.add_role(:restricted_liquid_tag, options.resource) }
    end

    trait :super_plus_single_resource_admin do
      transient do
        resource { nil }
      end

      after(:build) do |user, options|
        user.add_role(:super_admin)
        user.add_role(:single_resource_admin, options.resource)
      end
    end

    trait :trusted do
      after(:build) { |user| user.add_role(:trusted) }
    end

    trait :banned do
      after(:build) { |user| user.add_role(:banned) }
    end

    trait :invited do
      after(:build) do |user|
        user.registered = false
        user.registered_at = nil
      end
    end

    trait :ignore_mailchimp_subscribe_callback do
      after(:build) do |user|
        # rubocop:disable Lint/EmptyBlock
        user.define_singleton_method(:subscribe_to_mailchimp_newsletter) {}
        # rubocop:enable Lint/EmptyBlock
        # user.class.skip_callback(:validates, :after_create)
      end
    end

    trait :pro do
      after(:build) { |user| user.add_role(:pro) }
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
        create(:comment, user_id: user.id, commentable: article)
        user.update(comments_count: 1)
      end
    end

    trait :with_article_and_comment do
      after(:create) do |user|
        article = create(:article, user_id: user.id)
        create(:comment, user_id: user.id, commentable: article)
        user.update(articles_count: 1, comments_count: 1)
      end
    end

    trait :tag_moderator do
      after(:create) do |user|
        tag = create(:tag)
        user.add_role(:tag_moderator, tag)
      end
    end

    trait :without_profile do
      _skip_creating_profile { true }
    end

    trait :with_newsletters do
      email_newsletter { true }
      email_digest_periodic { true }
    end
  end
end
