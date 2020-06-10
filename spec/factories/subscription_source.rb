FactoryBot.define do
  factory :subscription_source do
    association :subscriber, factory: :user, strategy: :create
    association :subscription_sourceable, factory: :article

    author { subscription_sourceable.user }
  end
end
