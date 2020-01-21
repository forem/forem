FactoryBot.define do
  factory :reaction do
    user
    association :reactable, factory: :article
    reactable_type { "Article" }
    category { "like" }
  end

  factory :reading_reaction, class: "Reaction" do
    user
    association :reactable, factory: :article
    reactable_type { "Article" }
    category { "readinglist" }
  end
end
