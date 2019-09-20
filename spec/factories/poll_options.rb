FactoryBot.define do
  factory :poll_option do
    markdown { Faker::Hipster.words(number: 3) }
  end
end
