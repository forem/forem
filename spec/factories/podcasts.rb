FactoryBot.define do
  factory :podcast do
    title         { Faker::Beer.name }
    image         { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'fixtures', 'images', 'image1.jpeg'), 'image/jpeg') }
    description   { Faker::Hipster.paragraph(1) }
    slug          { "slug-#{rand(10_000)}" }
    feed_url      { "slug-#{rand(10_000)}" }
  end
end
