FactoryBot.define do
  factory :role do
    name { Role::ROLES[:admin] }
  end
end
