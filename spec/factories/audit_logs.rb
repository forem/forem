FactoryBot.define do
  factory :audit_log do
    category { Faker::Name.name }
    slug     { Faker::Creature::Animal }
    data     { { action: Faker::ProgrammingLanguage.name, controller: Faker::Lorem.word } }
  end
end
