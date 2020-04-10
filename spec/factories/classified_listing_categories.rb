FactoryBot.define do
  factory :classified_listing_category do
    name { "Education/Courses" }
    cost { [1, 5, 25].sample }
    rules  { Faker::Hipster.paragraph(sentence_count: 1) }

    trait :cfp do
      name { "Conference CFP" }
    end
  end
end
