FactoryBot.define do
  factory :page do
    title         { Faker::Book.title }
    body_markdown { Faker::Lorem.sentence }
    slug          { Faker::Internet.slug }
    description   { Faker::Lorem.sentence }
    template      { "contained" }
  end
end
