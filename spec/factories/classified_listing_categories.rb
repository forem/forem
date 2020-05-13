FactoryBot.define do
  factory :classified_listing_category do
    name { "Education/Courses" }
    cost { [1, 5, 25].sample }
    rules  { Faker::Hipster.paragraph(sentence_count: 1) }
    slug { "education" }
    social_preview_description { "Education" }
    social_preview_color { "#5aabe8" }

    trait :cfp do
      name { "Conference CFP" }
      slug { "cfp" }
      cost { 5 }
      social_preview_description { "Call For Proposal" }
      social_preview_color { "#f58f8d" }
    end

    trait :jobs do
      name { "Job Listings" }
      slug { "jobs" }
      cost { 1 }
      social_preview_description { "Now Hiring" }
      social_preview_color { "#53c3ad" }
    end
  end
end
