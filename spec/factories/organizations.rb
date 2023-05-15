FactoryBot.define do
  sequence(:slug) { |n| "org#{n}" }

  factory :organization do
    name               { Faker::Company.name }
    summary            { Faker::Hipster.paragraph(sentence_count: 1)[0..150] }
    profile_image      { Rails.root.join("app/assets/images/android-icon-36x36.png").open }
    url                { Faker::Internet.url }
    slug               { generate(:slug) }
    github_username    { "org#{rand(10_000)}" }
    twitter_username   { "org#{rand(10_000)}" }
    bg_color_hex       { Faker::Color.hex_color }
    text_color_hex     { Faker::Color.hex_color }
    proof              { Faker::Hipster.sentence }
  end
end
