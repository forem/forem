FactoryBot.define do
  factory :chat_channel_membership do
    user
    association :chat_channel, channel_type: "open"
  end
end
