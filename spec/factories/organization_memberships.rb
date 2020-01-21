FactoryBot.define do
  factory :organization_membership do
    association :user, factory: :user, strategy: :create
    association :organization, factory: :organization, strategy: :create
    type_of_user { "member" }

    after(:build) do |organization_membership|
      organization_membership.class.skip_callback(:create, :after, :update_user_organization_info_updated_at, raise: false)
    end
  end
end
