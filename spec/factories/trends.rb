FactoryBot.define do
  factory :trend do
    sequence(:name) { |n| "Trend #{n}" }
    sequence(:slug) { |n| "trend-#{n}" }
    description { "Algorithmically detected trend details." }
    centroid_embedding { Array.new(768) { rand } }
    score { 10.0 }
    articles_count { 1 }
    first_observed_at { Time.current }
    last_observed_at { Time.current }
  end

  factory :trend_membership do
    association :trend
    association :article
    distance { 0.1 }
  end
end
