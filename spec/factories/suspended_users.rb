FactoryBot.define do
  factory :suspended_user, class: "Users::Suspended" do
    sequence(:username_hash) do
      Digest::SHA256.hexdigest(Faker::Internet.unique.username)
    end
  end
end
