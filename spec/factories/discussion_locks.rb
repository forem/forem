FactoryBot.define do
  factory :discussion_lock do
    association :article, factory: :article, strategy: :create
    association :locking_user, factory: :user, strategy: :create

    reason { "This post has too many off-topic comments" }
    notes  { "Private notes" }
  end
end
