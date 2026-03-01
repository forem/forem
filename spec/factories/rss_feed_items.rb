FactoryBot.define do
  factory :rss_feed_item do
    rss_feed
    item_url { Faker::Internet.url(scheme: "https", path: "/posts/#{SecureRandom.hex(6)}") }
    title { Faker::Lorem.sentence }
    status { :pending }
    detected_at { Time.current }

    trait :imported do
      status { :imported }
      article
      processed_at { Time.current }
    end

    trait :skipped do
      status { :skipped }
      skip_reason { "Duplicate content" }
      processed_at { Time.current }
    end

    trait :error do
      status { :error }
      error_message { "Failed to create article" }
      processed_at { Time.current }
    end
  end
end
