FactoryBot.define do
  factory :reaction do
    reactable_id        { rand(10000) }
    user_id             { rand(10000) }
    reactable_type { "Article" }
    category { "like" }
  end
end
