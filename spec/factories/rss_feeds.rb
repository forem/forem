FactoryBot.define do
  factory :rss_feed do
    user
    feed_url { Faker::Internet.url(scheme: "https", path: "/feed.xml") }
    mark_canonical { false }
    referential_link { true }
    status { :active }

    # Skip feed URL validation in tests — it makes HTTP requests
    to_create do |instance|
      instance.save!(validate: false)
    end

    trait :paused do
      status { :paused }
    end

    trait :error do
      status { :error }
      last_error_message { "Connection timed out" }
    end

    trait :with_organization do
      fallback_organization factory: %i[organization]
    end

    trait :with_fallback_author do
      fallback_author factory: %i[user]
    end
  end
end
