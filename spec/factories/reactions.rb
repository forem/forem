FactoryBot.define do
  factory :reaction do
    reactable_id { rand(10000) }
    user
    reactable_type { "Article" }
    category { "like" }
  end
end
