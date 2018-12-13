FactoryBot.define do
  factory :podcast_episode do
    podcast_id    { rand(30) }
    title         { rand(30) }
    media_url     { Faker::Internet.url }
    website_url   { Faker::Internet.url }
    body          { Faker::Hipster.paragraph(1) }
    slug          { "slug-#{rand(10_000)}" }
    guid          { "guid-#{rand(10_000)}" }
    podcast
  end
end
