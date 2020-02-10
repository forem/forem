FactoryBot.define do
  factory :poll_option do
    poll
    markdown { Faker::Hipster.words(number: 3) }
  end
end
