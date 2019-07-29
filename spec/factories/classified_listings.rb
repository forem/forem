FactoryBot.define do
  factory :classified_listing do
    user
    title { Faker::Book.title + rand(100).to_s }
    body_markdown { Faker::Hipster.paragraph(2) }
    category { "education" }
    published { true }
    bumped_at { Time.current }
  end
end
