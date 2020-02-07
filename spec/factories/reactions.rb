FactoryBot.define do
  factory :reaction do
    user
    association :reactable, factory: :article
    category { "like" }
  end

  factory :reading_reaction, class: "Reaction" do
    user
    association :reactable, factory: :article
    category { "readinglist" }
  end
end
