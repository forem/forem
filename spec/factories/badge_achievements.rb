FactoryBot.define do
  factory :badge_achievement do
    user
    badge
    rewarder { user }
    rewarding_context_message_markdown "Hello [Yoho](/hey)"
  end
end
