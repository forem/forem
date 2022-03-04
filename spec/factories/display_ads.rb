FactoryBot.define do
  factory :display_ad do
    placement_area { "sidebar_left" }
    sequence(:body_markdown) { |n| "Hello _hey_ Hey hey #{n}" }
    organization
  end
end
