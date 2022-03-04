FactoryBot.define do
  factory :collection do
    user
    sequence(:slug) { |n| "slug-#{n}" }
  end

  trait :with_articles do
    transient do
      amount { 3 }
    end
    after(:create) do |collection, evaluator|
      create_list(:article, evaluator.amount, with_collection: collection, user: collection.user)
    end
  end
end
