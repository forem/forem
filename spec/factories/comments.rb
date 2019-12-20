FactoryBot.define do
  factory :comment do
    user
    body_markdown      { Faker::Hipster.paragraph(sentence_count: 1) }
    commentable_id     { rand(1000) }
    commentable_type   { "Article" }
    factory :article_comment do
      association :commentable, factory: :article
    end

    trait :with_path do
      after(:create) do |comment|
        Comments::CreateIdCodeJob.perform_now(comment.id)
      end
    end
  end
end
