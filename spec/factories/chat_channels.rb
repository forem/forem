FactoryBot.define do
  factory :chat_channel do
    channel_type { "open" }
    sequence(:slug) { |n| "slug-#{n}" }
  end

  trait :workshop do
    channel_name { "Workshop" }
  end
end
