FactoryBot.define do
  sequence(:podcast_slug) { |n| "slug-#{n}" }

  image = Rack::Test::UploadedFile.new(
    Rails.root.join("spec", "support", "fixtures", "images", "image1.jpeg"),
    "image/jpeg",
  )

  factory :podcast do
    title           { Faker::Beer.name }
    image           { image }
    description     { Faker::Hipster.paragraph(sentence_count: 1) }
    slug            { generate :podcast_slug }
    feed_url        { Faker::Internet.url }
    main_color_hex  { "ffffff" }
    published       { true }
  end
end
