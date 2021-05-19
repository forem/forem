FactoryBot.define do
  factory :discussion_lock do
    association :article, factory: :article, strategy: :create
    association :user, factory: :user, strategy: :create

    reason { "This post has too many off-topic comments" }
  end
end
