FactoryBot.define do
  factory :badge do
    title { Faker::Overwatch.quote }
    description { Faker::Lorem.sentence }
    badge_image { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "fixtures", "images", "image1.jpeg"), "image/jpeg") }
  end
end
