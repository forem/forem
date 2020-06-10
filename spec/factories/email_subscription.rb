FactoryBot.define do
  factory :email_subscription do
    association :subscriber, factory: :user, strategy: :create
    association :email_subscribable, factory: :article

    author { email_subscribable.user }
  end
end
