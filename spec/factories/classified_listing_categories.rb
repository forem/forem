FactoryBot.define do
  factory :classified_listing_category do
    name { "Education/Courses" }
    cost { [1, 5, 25].sample }
    rules  { Faker::Hipster.paragraph(sentence_count: 1) }
    slug { "education" }

    trait :cfp do
      name { "Conference CFP" }
      slug { "cfp" }
      cost { 5 }
    end
  end
end
