FactoryBot.define do
  factory :display_ad_event do
    category { DisplayAdEvent::CATEGORY_IMPRESSION }
    context_type { "home" }
    display_ad
  end
end
