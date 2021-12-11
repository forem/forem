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

    trait :user do
      association :reactable, factory: :user
    end
  end

  factory :vomit_reaction, class: "Reaction" do
    user { create(:user, :trusted) }
    association :reactable, factory: :article
    category { "vomit" }

    trait :user do
      association :reactable, factory: :user
    end

    trait :comment do
      association :reactable, factory: :comment
    end
  end
end
