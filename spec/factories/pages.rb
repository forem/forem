FactoryBot.define do
  factory :page do
    title { Faker::Book.title + rand(100).to_s }
    body_markdown { Faker::Book.title + rand(100).to_s }
    slug { "word-#{rand(10_000)}" }
    description { Faker::Book.title + rand(100).to_s }
    template { "contained" }
  end
end
