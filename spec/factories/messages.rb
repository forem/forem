FactoryBot.define do
  factory :message do
    message_markdown { Faker::Lorem.sentence }
    chat_channel

    trait :ignore_after_callback do
      after(:build) do |message|
        message.define_singleton_method(:evaluate_channel_permission) {}
        message.define_singleton_method(:evaluate_markdown) {}
      end
    end
  end
end
