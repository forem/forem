FactoryBot.define do
  sequence(:podcast_slug) { |n| "slug-#{n}" }

  image_path = Rails.root.join("spec/support/fixtures/images/image1.jpeg")

  factory :podcast do
    title           { Faker::Beer.name }
    image           { Rack::Test::UploadedFile.new(image_path, "image/jpeg") }
    description     { Faker::Hipster.paragraph(sentence_count: 1) }
    slug            { generate(:podcast_slug) }
    feed_url        { Faker::Internet.url }
    main_color_hex  { "ffffff" }
    published       { true }
    featured        { false }
  end
end
