FactoryBot.define do
  factory :collection do
    user
    slug { "word-#{rand(10_000)}" }
  end

  trait :with_articles do
    after(:create) do |collection|
      create_list(:article, 3, with_collection: collection, user: collection.user)
    end
  end
end
