FactoryBot.define do
  factory :user_optional_field do
    user
    label { "Pronoun" }
    value { "They/them" }
  end
end
