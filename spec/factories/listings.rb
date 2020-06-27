FactoryBot.define do
  factory :listing do
    user
    title { "#{Faker::Book.title} #{rand(1000)}" }
    body_markdown { Faker::Hipster.paragraph(sentence_count: 2) }
    published { true }
    bumped_at { Time.current }

    after(:build) do |cl|
      if cl.listing_category.blank?
        category = ListingCategory.first || create(:listing_category)
        cl.listing_category = category
      end
    end
  end
end
