FactoryBot.define do
  image = Rack::Test::UploadedFile.new(
    Rails.root.join("spec", "support", "fixtures", "images", "image1.jpeg"),
    "image/jpeg",
  )

  factory :badge do
    title { Faker::Games::Overwatch.quote }
    description { Faker::Lorem.sentence }
    badge_image { image }
  end
end
