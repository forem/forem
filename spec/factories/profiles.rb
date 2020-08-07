FactoryBot.define do
  factory :profile do
    user
    data { { name: "John Doe" } }
  end
end
