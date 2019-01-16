FactoryBot.define do
  image = Rack::Test::UploadedFile.new(
    File.join(Rails.root, "spec", "support", "fixtures", "images", "image1.jpeg"), "image/jpeg"
  )

  factory :podcast do
    title         { Faker::Beer.name }
    image         { image }
    description   { Faker::Hipster.paragraph(1) }
    slug          { "slug-#{rand(10_000)}" }
    feed_url      { Faker::Internet.url }
    after(:build) { |pod| pod.define_singleton_method(:pull_all_episodes) {} }
  end
end
