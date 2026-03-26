FactoryBot.define do
  factory :feed_source, class: "Feeds::Source" do
    user
    sequence(:feed_url) { |n| "https://example.com/feed#{n}.xml" }
    status { :healthy }

    trait :with_organization do
      organization
      after(:build) do |source|
        unless OrganizationMembership.exists?(user_id: source.user_id, organization_id: source.organization_id)
          create(:organization_membership, user: source.user, organization: source.organization,
                                           type_of_user: "admin")
        end
      end
    end

    trait :with_author do
      with_organization
      after(:build) do |source|
        author = create(:user)
        unless OrganizationMembership.exists?(user_id: author.id, organization_id: source.organization_id)
          create(:organization_membership, user: author, organization: source.organization,
                                           type_of_user: "member")
        end
        source.author_user_id = author.id
      end
    end

    trait :degraded do
      status { :degraded }
      consecutive_failures { 2 }
    end

    trait :failing do
      status { :failing }
      consecutive_failures { 5 }
    end

    trait :inactive do
      status { :inactive }
    end
  end
end
