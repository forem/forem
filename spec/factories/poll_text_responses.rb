FactoryBot.define do
  factory :poll_text_response do
    poll
    user
    text_content { Faker::Lorem.paragraph(sentence_count: 3) }
  end
end
