FactoryBot.define do
  factory :event do
    title { "My Exciting Live Stream" }
    sequence(:event_name_slug) { |n| "my-exciting-live-stream-#{n}" }
    sequence(:event_variation_slug) { |n| "march-31-#{n}" }
    description { "We will be building Forem live on Twitch!" }
    primary_stream_url { "https://twitch.tv/ThePracticalDev" }
    published { true }
    start_time { 1.day.from_now }
    end_time { 2.days.from_now }
    type_of { "live_stream" }

    trait :takeover do
      type_of { "takeover" }
    end

    trait :unpublished do
      published { false }
    end
  end
end
