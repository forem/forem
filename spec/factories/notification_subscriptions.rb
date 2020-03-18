FactoryBot.define do
  factory :notification_subscription do
    user
    association :notifiable, factory: :article
  end
end
