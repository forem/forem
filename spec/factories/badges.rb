FactoryBot.define do
  image_path = Rails.root.join("spec/support/fixtures/images/image1.jpeg")

  factory :badge do
    title       { Faker::Book.title + " #{rand(1000)}" }
    description { Faker::Lorem.sentence }
    badge_image { Rack::Test::UploadedFile.new(image_path, "image/jpeg") }
  end
end
