FactoryBot.define do
  factory :recommended_articles_list do
    sequence(:name) { |n| "#{Faker::Lorem.sentence}#{n}" }
    sequence(:article_ids) { |n| [n, n + 1, n + 2] }
    expires_at { 1.day.from_now }
    placement_area { "main_feed" }
    user
  end
end
