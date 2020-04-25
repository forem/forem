FactoryBot.define do
  factory :classified_listing do
    user
    title { Faker::Book.title + " #{rand(1000)}" }
    body_markdown { Faker::Hipster.paragraph(sentence_count: 2) }
    published { true }
    bumped_at { Time.current }

    after(:build) do |cl|
      if cl.classified_listing_category_id.blank?
        category = ClassifiedListingCategory.first || create(:classified_listing_category)
        cl.classified_listing_category_id = category.id
      end
    end
  end
end
