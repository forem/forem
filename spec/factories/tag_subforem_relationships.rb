FactoryBot.define do
  factory :tag_subforem_relationship do
    tag { association(:tag) }
    subforem { association(:subforem) }

    trait :with_tag do
      after(:build) do |relationship|
        relationship.tag = create(:tag)
      end
    end

    trait :with_subforem do
      after(:build) do |relationship|
        relationship.subforem = create(:subforem)
      end
    end
  end
end