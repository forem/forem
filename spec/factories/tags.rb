FactoryBot.define do
  sequence(:name) { |n| "tag#{n}" }

  factory :tag do
    name { generate :name }
    supported { true }
  end

  trait :with_colors do
    bg_color_hex { "#000000" }
    text_color_hex { "#ffffff" }
  end
end
