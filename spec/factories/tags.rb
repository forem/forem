FactoryBot.define do
  sequence(:name) { |n| "tag#{n}" }

  factory :tag do
    name { generate :name }
    supported { true }

    trait :search_indexed do
      # rubocop:disable Style/SymbolProc
      after(:create) { |tag| tag.index_to_elasticsearch_inline }
      # rubocop:enable Style/SymbolProc
    end
  end
end
