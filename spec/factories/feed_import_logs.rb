FactoryBot.define do
  factory :feed_import_log, class: "Feeds::ImportLog" do
    user
    status { :completed }
    items_in_feed { 5 }
    items_imported { 3 }
    items_skipped { 2 }
    items_failed { 0 }
    duration_seconds { 1.5 }
    feed_url { "https://example.com/feed.xml" }

    trait :with_source do
      association :feed_source
      after(:build) do |log|
        log.user = log.feed_source.user
        log.feed_url = log.feed_source.feed_url
      end
    end

    trait :failed do
      status { :failed }
      error_message { "Connection timed out" }
      items_imported { 0 }
      items_skipped { 0 }
    end

    trait :with_items do
      after(:create) do |log|
        create_list(:feed_import_item, 3, :imported, import_log: log)
        create_list(:feed_import_item, 2, :skipped, import_log: log)
      end
    end
  end
end
