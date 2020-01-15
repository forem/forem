FactoryBot.define do
  factory :canned_response do
    sequence(:content) { |n| "#{Faker::Lorem.sentence}#{n}" }

    user
    type_of { "personal_comment" }
    content_type { "body_markdown" }
    title { generate :title }
  end
end
