FactoryBot.define do
  factory :suspended_username, class: "Users::SuspendedUsername" do
    transient do
      username { Faker::Internet.unique.username }
    end

    after(:build) do |user, evaluator|
      user.username_hash = Users::SuspendedUsername.hash_username(evaluator.username)
    end
  end
end
