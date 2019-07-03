FactoryBot.define do
  factory :poll_option do
    markdown { Faker::Hipster.words(3) }
  end
end
