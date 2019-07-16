FactoryBot.define do
  factory :sponsorship do
    user
    organization
    level { "bronze" }
  end
end
