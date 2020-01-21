FactoryBot.define do
  factory :comment, aliases: [:article_comment] do
    user
    body_markdown { Faker::Hipster.paragraph(sentence_count: 1) }
    commentable_type { "Article" }
    association :commentable, factory: :article
  end
end
