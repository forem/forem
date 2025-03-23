FactoryBot.define do
  factory :email do
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.sentence }
    status { "active" }
  end
end
