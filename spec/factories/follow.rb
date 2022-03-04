FactoryBot.define do
  factory :follow do
    association :follower, factory: :user
    association :followable, factory: :organization
  end
end
