FactoryBot.define do
  factory :organization_membership do
    # TODO: replace with `user` and `organization` since this currently doesn't have a belongs_to relationship
    user_id { rand(6) }
    organization_id { rand(6) }
    type_of_user { "member" }
  end
end
