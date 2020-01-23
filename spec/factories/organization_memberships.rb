FactoryBot.define do
  factory :organization_membership do
    user
    organization
    type_of_user { "member" }
  end
end
