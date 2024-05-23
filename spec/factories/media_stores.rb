FactoryBot.define do
  factory :media_store do
    original_url { "http://example.com/image.jpg" }
    output_url { nil }
    media_type { "image" }
  end
end
