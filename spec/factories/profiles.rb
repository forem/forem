FactoryBot.define do
  factory :profile do
    association :user, factory: :user, strategy: :create
    data { { name: "John Doe" } }
  end
end
