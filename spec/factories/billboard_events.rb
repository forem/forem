FactoryBot.define do
  factory :billboard_event do
    category { BillboardEvent::CATEGORY_IMPRESSION }
    context_type { "home" }
    association :billboard, factory: :display_ad
  end
end
