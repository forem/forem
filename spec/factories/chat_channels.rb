FactoryBot.define do
  factory :chat_channel do
    channel_type { "open" }
    slug { rand(10_000_000_000).to_s }
  end

  trait :workshop do
    channel_name { "Workshop" }
  end
end
