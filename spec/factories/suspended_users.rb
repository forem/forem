FactoryBot.define do
  factory :suspended_user, class: "Users::Suspended" do
    transient do
      username { Faker::Internet.unique.username }
    end

    after(:build) do |user, evaluator|
      user.username_hash = Users::Suspended.hash_username(evaluator.username)
    end
  end
end
