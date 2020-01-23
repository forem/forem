FactoryBot.define do
  factory :user_block do
    association :blocker, factory: :user
    association :blocked, factory: :user
    config { "default" }
  end
end
