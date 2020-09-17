FactoryBot.define do
  factory :display_ad_event do
    category { "impression" }
    context_type { "home" }
    display_ad
  end
end
