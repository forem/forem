FactoryBot.define do
  factory :message do
    message_markdown { Faker::Lorem.sentence }
    chat_channel
  end
end
