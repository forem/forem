FactoryBot.define do
  factory :reaction do
    reactable_id { rand(10_000) }
    user
    reactable_type { "Article" }
    category { "like" }
  end

  factory :reading_reaction, class: "Reaction" do
    user
    reactable { create(:article) }
    category { "readinglist" }
  end
end
