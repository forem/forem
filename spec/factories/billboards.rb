FactoryBot.define do
  factory :billboard, class: "Billboard", aliases: %i[display_ad] do
    placement_area { "sidebar_left" }
    sequence(:body_markdown) { |n| "Hello _hey_ Hey hey #{n}" }
    organization
    priority { false }
  end
end
