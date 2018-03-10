FactoryBot.define do
  factory :event do
    title { Faker::Company.bs }
    description_markdown { Faker::Hipster.paragraph(2) }
    starts_at { Time.now }
    ends_at { Time.now + 3660 }
    category { "AMA" }
  end
end
