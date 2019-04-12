FactoryBot.define do
  factory :classified_listing do
    title { Faker::Book.title + rand(100).to_s }
    body_markdown { Faker::Hipster.paragraph(2) }
    category { "courses" }
  end
end
  