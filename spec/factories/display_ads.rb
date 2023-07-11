FactoryBot.define do
  factory :display_ad do
    transient do
      geo { nil }
    end

    placement_area { "sidebar_left" }
    sequence(:body_markdown) { |n| "Hello _hey_ Hey hey #{n}" }
    organization
    geo_array { geo }
    geo_text { geo&.join(",") }
    priority { false }
  end
end
