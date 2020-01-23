FactoryBot.define do
  factory :display_ad do
    placement_area { "sidebar_left" }
    body_markdown { "Hello _hey_ Hey hey" }
    organization
  end
end
