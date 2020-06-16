FactoryBot.define do
  factory :user_subscription do
    association :subscriber, factory: :user, strategy: :create
    association :user_subscription_sourceable, factory: :article

    author { user_subscription_sourceable.user }
  end
end
