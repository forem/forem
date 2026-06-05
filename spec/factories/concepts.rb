FactoryBot.define do
  factory :concept do
    sequence(:name) { |n| "Concept #{n}" }
    sequence(:slug) { |n| "concept-#{n}" }
    description { "A semantically tracked concept." }
    anchor_embedding { Array.new(768) { rand } }
  end

  factory :concept_membership do
    association :concept
    association :record, factory: :article
    distance { 0.1 }
  end

  factory :concept_daily_metric do
    association :concept
    date { Date.today }
    articles_count { 5 }
    page_views { 100 }
    reactions_count { 10 }
    comments_count { 3 }
    popularity_score { 68.0 }
  end
end
