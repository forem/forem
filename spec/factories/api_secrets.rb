FactoryBot.define do
  factory :api_secret do
    user
    description { Faker::Lorem.sentence }
    secret      { SecureRandom.base58(24) }
  end

  trait :org_admin do
    after(:create) do |api_secret|
      org = create(:organization)
      create(:organization_membership, user_id: api_secret.user.id, organization_id: org.id, type_of_user: "admin")
    end
  end
end
