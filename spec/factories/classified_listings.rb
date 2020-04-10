FactoryBot.define do
  factory :classified_listing do
    user
    title { Faker::Book.title + " #{rand(1000)}" }
    body_markdown { Faker::Hipster.paragraph(sentence_count: 2) }
    category { "education" }
    published { true }
    bumped_at { Time.current }
  end
end
