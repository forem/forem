FactoryBot.define do
  factory :event do
    title { Faker::Company.bs }
    description_markdown { Faker::Hipster.paragraph(sentence_count: 2) }
    starts_at { Time.current }
    ends_at { 3660.seconds.from_now }
    category { "AMA" }
  end
end
