FactoryBot.define do
  factory :suspended_user, class: "Users::Suspended" do
    sequence(:username_hash) do
      Users::Suspended.hash_username(Faker::Internet.unique.username)
    end
  end
end
