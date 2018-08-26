FactoryBot.define do
  factory :chat_channel do
    channel_type { "open" }
    slug { rand(10000000000).to_s }
  end

  trait :workshop do
    channel_name { "Workshop" }
  end
end
