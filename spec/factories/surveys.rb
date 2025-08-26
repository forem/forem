FactoryBot.define do
  factory :survey do
    title { Faker::Lorem.word }
    active { true }
    display_title { true }
  end
end