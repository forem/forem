FactoryBot.define do
  factory :podcast_episode do
    sequence(:slug) { |n| "slug-#{n}" }
    sequence(:guid) { |n| "guid-#{n}" }
    podcast_id    { rand(30) }
    title         { rand(30) }
    media_url     { Faker::Internet.url }
    website_url   { Faker::Internet.url }
    body          { Faker::Hipster.paragraph(sentence_count: 1) }
    podcast
  end
end
