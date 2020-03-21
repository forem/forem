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

  factory :thumbsdown_reaction, class: "Reaction" do
    user
    association :reactable, factory: :article
    category { "thumbsdown" }
  end

  factory :vomit_reaction, class: "Reaction" do
    user
    association :reactable, factory: :article
    category { "vomit" }
  end
end
