FactoryBot.define do
  image = Rack::Test::UploadedFile.new(
    File.join(Rails.root, "spec", "support", "fixtures", "images", "image1.jpeg"), "image/jpeg"
  )

  factory :badge do
    title { Faker::Overwatch.quote }
    description { Faker::Lorem.sentence }
    badge_image { image }
  end
end
