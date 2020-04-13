FactoryBot.define do
  factory :optional_field do
    user
    field { "Pronoun" }
    value { "They/them" }
  end
end
