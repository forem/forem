FactoryBot.define do
  factory :user_optional_field do
    user
    field { "Pronoun" }
    value { "They/them" }
  end
end
