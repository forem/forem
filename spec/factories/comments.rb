FactoryBot.define do
  factory :comment do
    user
    body_markdown      { Faker::Hipster.paragraph(1) }
    commentable_id     { rand(1000) }
    commentable_type   { "Article" }
  end
end
