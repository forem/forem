FactoryBot.define do
  factory :chat_channel do
    channel_type { "open" }
    channel_name { Faker::Name.name }
    sequence(:slug) { |n| "slug-#{n}" }
  end
end
