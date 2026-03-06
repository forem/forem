FactoryBot.define do
  factory :feed_import_item, class: "Feeds::ImportItem" do
    association :import_log, factory: :feed_import_log
    feed_item_url { Faker::Internet.url }
    feed_item_title { Faker::Lorem.sentence }
    status { :imported }

    trait :imported do
      status { :imported }
      article
    end

    trait :skipped do
      status { :skipped_duplicate }
    end

    trait :failed do
      status { :failed }
      error_message { "Article creation failed" }
    end
  end
end
